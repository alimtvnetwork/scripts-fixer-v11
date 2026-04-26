#!/usr/bin/env bash
# 64-startup-add :: methods-macos.sh
# macOS app methods: LaunchAgent plist, login-item via osascript,
#                    launchctl setenv (env). shell-rc env is shared from methods-linux.sh.
#
# Honours:
#   STARTUP_TAG_PREFIX   (default: "lovable-startup")
#   STARTUP_FORCE_REPLACE (default: 0)
# Every error path logs exact path + reason (CODE RED rule).

STARTUP_TAG_PREFIX="${STARTUP_TAG_PREFIX:-lovable-startup}"
STARTUP_FORCE_REPLACE="${STARTUP_FORCE_REPLACE:-0}"

_tagged_label() { printf 'com.%s.%s' "$STARTUP_TAG_PREFIX" "$1"; }

_launchagents_dir() { printf '%s/Library/LaunchAgents' "$HOME"; }

_ensure_dir_mac() {
  local d="$1"
  if [ -d "$d" ]; then return 0; fi
  if mkdir -p "$d" 2>/dev/null; then return 0; fi
  log_file_error "$d" "mkdir failed"
  return 1
}

# XML-escape &, <, > for plist values.
_xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  printf '%s' "$s"
}

# ---- 1) LaunchAgent plist ----
write_launchagent_plist() {
  local name="$1" path="$2" args="${3:-}"
  local label;  label=$(_tagged_label "$name")
  local dir;    dir=$(_launchagents_dir)
  local file="$dir/${label}.plist"

  _ensure_dir_mac "$dir" || return 1

  if [ -f "$file" ] && [ "$STARTUP_FORCE_REPLACE" != "1" ]; then
    log_info "[64] LaunchAgent already exists at $file -- replacing (upsert)"
    # Bootout the old one first so the new plist takes effect on load.
    if command -v launchctl >/dev/null 2>&1; then
      launchctl bootout "gui/$(id -u)" "$file" >/dev/null 2>&1 || true
    fi
  fi

  # Build ProgramArguments array
  local prog_args=""
  prog_args+=$'    <string>'"$(_xml_escape "$path")"$'</string>\n'
  if [ -n "$args" ]; then
    # Naive split on whitespace -- callers wanting exact arg arrays should pre-quote.
    local a
    for a in $args; do
      prog_args+=$'    <string>'"$(_xml_escape "$a")"$'</string>\n'
    done
  fi

  {
    printf '<?xml version="1.0" encoding="UTF-8"?>\n'
    printf '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
    printf '<plist version="1.0">\n'
    printf '<dict>\n'
    printf '  <key>Label</key>\n  <string>%s</string>\n' "$(_xml_escape "$label")"
    printf '  <key>ProgramArguments</key>\n  <array>\n%s  </array>\n' "$prog_args"
    printf '  <key>RunAtLoad</key>\n  <true/>\n'
    printf '  <key>KeepAlive</key>\n  <false/>\n'
    printf '  <key>ProcessType</key>\n  <string>Background</string>\n'
    printf '  <key>StandardOutPath</key>\n  <string>%s/Library/Logs/%s.out.log</string>\n' "$(_xml_escape "$HOME")" "$(_xml_escape "$label")"
    printf '  <key>StandardErrorPath</key>\n  <string>%s/Library/Logs/%s.err.log</string>\n' "$(_xml_escape "$HOME")" "$(_xml_escape "$label")"
    printf '  <key>X-Lovable-Tag</key>\n  <string>%s</string>\n' "$(_xml_escape "$STARTUP_TAG_PREFIX")"
    printf '  <key>X-Lovable-Name</key>\n  <string>%s</string>\n' "$(_xml_escape "$name")"
    printf '</dict>\n</plist>\n'
  } > "$file" 2>/dev/null \
      || { log_file_error "$file" "write failed"; return 1; }

  chmod 644 "$file" 2>/dev/null || true
  log_ok "[64] LaunchAgent plist written: $file"

  # Try to load it with the modern bootstrap API. Fail soft in CI / non-mac.
  if command -v launchctl >/dev/null 2>&1; then
    if launchctl bootstrap "gui/$(id -u)" "$file" >/dev/null 2>&1; then
      log_ok "[64] launchctl bootstrap gui/$(id -u) ${label}"
    else
      log_warn "[64] launchctl bootstrap failed for $file -- run 'launchctl bootstrap gui/\$(id -u) $file' interactively (needs a real GUI session)."
    fi
  else
    log_warn "[64] launchctl not found -- plist written but not loaded. Will activate on next login."
  fi
  return 0
}

# ---- 2) Login Item via osascript ----
add_login_item() {
  local name="$1" path="$2" hidden="${3:-false}"
  local tagged_name; tagged_name=$(_tagged_label "$name")

  if ! command -v osascript >/dev/null 2>&1; then
    log_warn "[64] osascript not available -- cannot add login item for $name. Skipping (use LaunchAgent on non-macOS)."
    return 1
  fi

  if [ ! -e "$path" ]; then
    log_file_error "$path" "login-item target does not exist"
    return 1
  fi

  # Remove any existing entry with the same tagged name first (idempotent).
  osascript <<APPLESCRIPT >/dev/null 2>&1 || true
tell application "System Events"
  try
    delete login item "$tagged_name"
  end try
end tell
APPLESCRIPT

  if osascript <<APPLESCRIPT >/dev/null 2>&1
tell application "System Events"
  make login item at end with properties {name:"$tagged_name", path:"$path", hidden:$hidden}
end tell
APPLESCRIPT
  then
    log_ok "[64] login item added: $tagged_name -> $path (hidden=$hidden)"
    return 0
  else
    log_file_error "$path" "osascript failed to add login item ($tagged_name)"
    return 1
  fi
}

# ---- 3) launchctl setenv (env) ----
write_launchctl_env() {
  local key="$1" value="$2"

  if ! command -v launchctl >/dev/null 2>&1; then
    log_warn "[64] launchctl not available -- cannot setenv $key. Falling back to shell-rc env."
    write_shell_rc_env "$key" "$value"
    return $?
  fi

  if launchctl setenv "$key" "$value" >/dev/null 2>&1; then
    log_ok "[64] launchctl setenv ${key}=*** (current GUI session)"
  else
    log_warn "[64] launchctl setenv ${key} failed (no GUI session?). Falling back to shell-rc env."
    write_shell_rc_env "$key" "$value"
    return $?
  fi

  # launchctl setenv is process-scoped to launchd and is lost on reboot.
  # Mirror it to shell-rc so it survives logout/reboot too.
  write_shell_rc_env "$key" "$value"
  return $?
}

# Allow direct invocation for debugging:
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  . "$(dirname "$0")/../../_shared/logger.sh"
  . "$(dirname "$0")/../../_shared/file-error.sh"
  . "$(dirname "$0")/detect.sh"
  . "$(dirname "$0")/methods-linux.sh"   # for write_shell_rc_env fallback
  fn="${1:-write_launchagent_plist}"; shift || true
  "$fn" "$@"
fi
