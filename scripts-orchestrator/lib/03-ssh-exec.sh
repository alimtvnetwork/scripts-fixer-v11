#!/usr/bin/env bash
# 03-ssh-exec.sh -- ssh wrapper with ControlMaster multiplexing for speed.

ORCH_HOME="${ORCH_HOME:-$HOME/.ssh/Orchestrator}"
ORCH_CTRL_DIR="$ORCH_HOME/control"

ensure_orch_home() {
  if ! mkdir -p "$ORCH_HOME" "$ORCH_CTRL_DIR" 2>/dev/null; then
    log_file_error "$ORCH_HOME" "mkdir failed (permission or disk?)"
    return 1
  fi
  chmod 700 "$ORCH_HOME" "$ORCH_CTRL_DIR" 2>/dev/null || true
}

# Run a shell snippet on a remote alias. Streams stdout, returns the remote exit code.
ssh_run() {
  local alias="$1"; shift
  local script="$*"
  if [ -z "$alias" ] || [ -z "$script" ]; then
    log_error "ssh_run: usage: ssh_run <alias> <shell-snippet>"
    return 2
  fi
  ensure_orch_home || return 1
  ssh \
    -o ControlMaster=auto \
    -o ControlPath="$ORCH_CTRL_DIR/%C" \
    -o ControlPersist=60s \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    "$alias" \
    "bash -lc $(printf '%q' "$script")"
}

# Copy a local file to a remote alias path. CODE-RED: name the path on failure.
ssh_put() {
  local alias="$1" local_path="$2" remote_path="$3"
  if [ ! -f "$local_path" ]; then
    log_file_error "$local_path" "ssh_put: local file not found"
    return 1
  fi
  if ! scp -o ControlPath="$ORCH_CTRL_DIR/%C" \
           -o BatchMode=yes \
           "$local_path" "$alias:$remote_path"; then
    log_file_error "$alias:$remote_path" "ssh_put: scp failed"
    return 1
  fi
}
