#!/usr/bin/env bash
# Root dispatcher for Linux installer toolkit.
# Verbs: install | check | repair | uninstall | --list | -I <id> | --parallel N
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
export SCRIPT_ID="root"
. "$ROOT/_shared/logger.sh"
. "$ROOT/_shared/pkg-detect.sh"
. "$ROOT/_shared/parallel.sh"
. "$ROOT/_shared/file-error.sh"
. "$ROOT/_shared/registry.sh"

VERB=""; ONLY_ID=""; PARALLEL=1

while [ $# -gt 0 ]; do
  case "$1" in
    install|check|repair|uninstall) VERB="$1"; shift ;;
    --list)        VERB="list"; shift ;;
    -I)            ONLY_ID="$2"; shift 2 ;;
    --parallel)    PARALLEL="$2"; shift 2 ;;
    -h|--help)     VERB="help"; shift ;;
    *) log_warn "Unknown arg: $1"; shift ;;
  esac
done

show_help() {
  cat <<EOF
Linux Installer Toolkit (v0.114.0)

Verbs:
  install              Install scripts
  check                Verify install state
  repair               Re-run failed installs
  uninstall            Remove installed packages
  --list               List all registered scripts
  -I <id>              Restrict to a single script id
  --parallel <N>       Run N installs in parallel (install verb only)
EOF
}

run_one() {
  local id="$1" verb="$2"
  local folder
  folder=$(registry_get_folder "$id")
  if [ -z "$folder" ]; then
    log_err "Unknown script id: $id"; return 1
  fi
  local script="$ROOT/$folder/run.sh"
  if [ ! -f "$script" ]; then
    log_file_error "$script" "script not yet implemented (phase pending)"
    return 0
  fi
  log_info "[$id] $verb -> $folder"
  bash "$script" "$verb"
}

case "${VERB:-help}" in
  help) show_help ;;
  list) registry_list_all | column -t -s$'\t' ;;
  install|check|repair|uninstall)
    if [ -n "$ONLY_ID" ]; then
      run_one "$ONLY_ID" "$VERB"
    else
      ids=$(registry_list_ids)
      if [ "$VERB" = "install" ] && [ "$PARALLEL" -gt 1 ]; then
        log_info "Running install in parallel (N=$PARALLEL)"
        cmds=()
        for id in $ids; do
          cmds+=("bash '$ROOT/run.sh' install -I $id")
        done
        run_parallel "$PARALLEL" "${cmds[@]}"
      else
        for id in $ids; do
          run_one "$id" "$VERB" || log_warn "[$id] returned non-zero"
        done
      fi
    fi
    ;;
  *) show_help ;;
esac
