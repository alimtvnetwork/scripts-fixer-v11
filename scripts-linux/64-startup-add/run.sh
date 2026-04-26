#!/usr/bin/env bash
# 64-startup-add  --  Cross-OS startup-add (apps + env vars), Unix side.
# Subverbs: app | env | list | remove
# Methods are auto-detected per OS (Linux: autostart|systemd-user|shell-rc;
# macOS: launchagent|login-item|shell-rc). Use --interactive for picker.
#
# Per-run logs: $ROOT/.logs/64/<TIMESTAMP>/{command.txt,manifest.json,session.log}
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export SCRIPT_ID="64"
. "$ROOT/_shared/logger.sh"
. "$ROOT/_shared/file-error.sh"

CONFIG="$SCRIPT_DIR/config.json"
LOGS_ROOT="$ROOT/.logs/64"
TS="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$LOGS_ROOT/$TS"

# helpers loaded in later steps (8-11). Stub-tolerant for now.
[ -f "$SCRIPT_DIR/helpers/detect.sh" ]       && . "$SCRIPT_DIR/helpers/detect.sh"
[ -f "$SCRIPT_DIR/helpers/methods-linux.sh" ]&& . "$SCRIPT_DIR/helpers/methods-linux.sh"
[ -f "$SCRIPT_DIR/helpers/methods-macos.sh" ]&& . "$SCRIPT_DIR/helpers/methods-macos.sh"
[ -f "$SCRIPT_DIR/helpers/listrm.sh" ]       && . "$SCRIPT_DIR/helpers/listrm.sh"

ensure_run_dir() {
  mkdir -p "$RUN_DIR/hosts" 2>/dev/null \
    || { log_file_error "$RUN_DIR" "mkdir failed"; return 1; }
  printf '%s\n' "$0 $*" > "$RUN_DIR/command.txt"
  ln -sfn "$TS" "$LOGS_ROOT/latest" 2>/dev/null || true
}

usage() {
  cat <<EOF
Usage: ./run.sh -I 64 -- <subverb> [args]

Subverbs:
  app  <path>     [--method M] [--name N] [--args "..."] [--interactive]
  env  KEY=VALUE  [--scope user] [--method shell-rc|systemd-env|launchctl]
  list            [--scope user|all]
  remove <name>   [--method ...]

Linux methods : autostart | systemd-user | shell-rc
macOS  methods: launchagent | login-item | shell-rc

Default per OS (when --method omitted):
  Linux GUI    -> autostart
  Linux headless -> systemd-user
  macOS        -> launchagent
EOF
}

main() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    app)    ensure_run_dir; cmd_app    "$@"; exit $? ;;
    env)    ensure_run_dir; cmd_env    "$@"; exit $? ;;
    list)   cmd_list   "$@"; exit $? ;;
    remove) ensure_run_dir; cmd_remove "$@"; exit $? ;;
    ""|help|-h|--help) usage; exit 0 ;;
    *) log_warn "[64] Unknown subverb: '$sub'"; usage; exit 1 ;;
  esac
}

# Stubs filled in by Steps 8-11
cmd_app()    { log_warn "[64] cmd_app stub -- implemented in Step 9 (Linux) / Step 10 (macOS)";  return 0; }
cmd_env()    { log_warn "[64] cmd_env stub -- implemented in Step 10";                              return 0; }
cmd_list()   { log_warn "[64] cmd_list stub -- implemented in Step 11";                             return 0; }
cmd_remove() { log_warn "[64] cmd_remove stub -- implemented in Step 11";                           return 0; }

main "$@"
