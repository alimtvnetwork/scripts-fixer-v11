#!/usr/bin/env bash
# 08-bootstrap.sh -- password->key bootstrap for one remote host.

bootstrap_host() {
  local alias="$1"
  if [ -z "$alias" ]; then
    log_error "bootstrap_host: usage: bootstrap_host <host-alias>"
    return 2
  fi

  local hostname user port role group key_strategy
  hostname="$(inventory_get_field "$alias" hostname)"
  user="$(inventory_get_field "$alias" user)"
  port="$(inventory_get_field "$alias" port)"
  group="$(inventory_get_field "$alias" group)"
  : "${port:=22}"
  : "${user:=$USER}"

  if [ -z "$hostname" ]; then
    log_error "bootstrap_host: alias=$alias has no hostname in inventory"
    return 1
  fi

  ensure_orch_home || return 1
  local key_path="$ORCH_HOME/id_ed25519"
  # Per-host key strategy: read group's KeyStrategy from groups.conf if available.
  local groups_file="$INVENTORY_DIR/groups.conf"
  if [ -f "$groups_file" ]; then
    key_strategy="$(awk -v g="$group" '
      /^\[.*\]$/ { gsub(/^\[|\]$/,"",$0); cur=$0; next }
      cur==g && /^[ \t]*key_strategy[ \t]*=/ {
        sub(/^[^=]*=[ \t]*/,"",$0); print; exit
      }' "$groups_file")"
  fi
  if [ "$key_strategy" = "per-host" ]; then
    key_path="$ORCH_HOME/id_ed25519_${alias}"
  fi

  log_step "bootstrap: alias=$alias host=$hostname user=$user port=$port keyStrategy=${key_strategy:-common}"

  # 1. Generate keypair if missing.
  if [ ! -f "$key_path" ]; then
    log_info "bootstrap: generating ed25519 keypair at $key_path"
    if ! ssh-keygen -t ed25519 -N '' -C "ssh-orchestrator@$(hostname)" -f "$key_path" >/dev/null; then
      log_file_error "$key_path" "bootstrap: ssh-keygen failed"
      return 1
    fi
  else
    log_dim "bootstrap: reusing existing key $key_path"
  fi

  # 2. Prompt for password (once) and copy public key. Requires sshpass.
  if ! command -v sshpass >/dev/null 2>&1; then
    log_error "bootstrap: sshpass not installed (apt-get install -y sshpass)"
    return 1
  fi
  printf 'Password for %s@%s: ' "$user" "$hostname" >&2
  stty -echo 2>/dev/null; IFS= read -r _PW; stty echo 2>/dev/null; printf '\n' >&2
  if ! sshpass -p "$_PW" ssh-copy-id -i "$key_path.pub" \
         -o StrictHostKeyChecking=accept-new \
         -p "$port" "$user@$hostname" >/dev/null 2>&1; then
    log_file_error "$key_path.pub" "bootstrap: ssh-copy-id failed for $user@$hostname:$port"
    unset _PW
    return 1
  fi
  unset _PW

  # 3. Write/refresh ~/.ssh/config alias entry.
  local cfg="$HOME/.ssh/config"
  if [ ! -f "$cfg" ]; then
    if ! touch "$cfg"; then
      log_file_error "$cfg" "bootstrap: cannot create ssh config"
      return 1
    fi
    chmod 600 "$cfg"
  fi
  if grep -q "^Host $alias\$" "$cfg" 2>/dev/null; then
    log_dim "bootstrap: alias '$alias' already in $cfg, leaving as-is"
  else
    {
      printf '\n# Added by ssh-orchestrator on %s\n' "$(_ts)"
      printf 'Host %s\n  HostName %s\n  User %s\n  Port %s\n  IdentityFile %s\n  IdentitiesOnly yes\n' \
             "$alias" "$hostname" "$user" "$port" "$key_path"
    } >> "$cfg"
    log_ok "bootstrap: appended alias '$alias' to $cfg"
  fi

  # 4. Verify key auth works.
  if ssh -o BatchMode=yes -o IdentitiesOnly=yes -i "$key_path" -p "$port" "$user@$hostname" true; then
    log_ok "bootstrap: key auth verified for alias=$alias"
  else
    log_error "bootstrap: key auth verification failed for alias=$alias"
    return 1
  fi
}
