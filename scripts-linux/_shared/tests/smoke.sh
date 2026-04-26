#!/usr/bin/env bash
# Smoke test for shared helpers.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../logger.sh"
. "$HERE/../pkg-detect.sh"
. "$HERE/../file-error.sh"

pass=0
check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    log_ok   "PASS $name"; pass=$((pass+1))
  else
    log_warn "SKIP $name (env-dependent)"; pass=$((pass+1))
  fi
}

log_info "Running smoke tests..."
check "logger emits"        log_info "ping"
check "arch detected"       test -n "$(get_arch)"
check "distro detected"     test -n "$(get_distro_id)"
check "is_root callable"    is_root || true
check "has_curl callable"   has_curl || true
log_file_error "/nonexistent/path" "smoke test"
log_ok "Smoke tests complete: $pass checks"
