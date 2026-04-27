#!/usr/bin/env bash
# 01-logger.sh -- colored + structured logger.
# CODE-RED rule: every file/path error must include the exact path + reason.

if [ -t 1 ]; then
  C_RED=$'\e[31m'; C_GRN=$'\e[32m'; C_YLW=$'\e[33m'
  C_BLU=$'\e[34m'; C_CYN=$'\e[36m'; C_DIM=$'\e[2m'; C_RST=$'\e[0m'
else
  C_RED=; C_GRN=; C_YLW=; C_BLU=; C_CYN=; C_DIM=; C_RST=
fi

_ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

log_info()  { printf '%s %s[INFO ]%s %s\n' "$(_ts)" "$C_CYN" "$C_RST" "$*"; }
log_ok()    { printf '%s %s[ OK  ]%s %s\n' "$(_ts)" "$C_GRN" "$C_RST" "$*"; }
log_warn()  { printf '%s %s[WARN ]%s %s\n' "$(_ts)" "$C_YLW" "$C_RST" "$*" >&2; }
log_step()  { printf '%s %s[STEP ]%s %s\n' "$(_ts)" "$C_BLU" "$C_RST" "$*"; }
log_dim()   { printf '%s %s%s%s\n'         "$(_ts)" "$C_DIM" "$*"  "$C_RST"; }

# CODE-RED helper: never log a path error without naming the path AND the reason.
log_file_error() {
  # $1 = path, $2 = reason
  local path="${1:-<unknown>}"
  local reason="${2:-<no reason supplied>}"
  printf '%s %s[FILE-ERROR]%s path=%s reason=%s\n' \
    "$(_ts)" "$C_RED" "$C_RST" "$path" "$reason" >&2
}

log_error() {
  printf '%s %s[ERROR]%s %s\n' "$(_ts)" "$C_RED" "$C_RST" "$*" >&2
}
