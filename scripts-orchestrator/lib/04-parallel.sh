#!/usr/bin/env bash
# 04-parallel.sh -- bounded parallel job runner. Pure bash + xargs.
# Usage:
#   run_parallel <max-concurrency> <fn-name> -- arg1 arg2 arg3 ...
# Calls "<fn-name> <argN>" for each arg, up to <max-concurrency> at a time.
# Exit code: 0 if all jobs succeeded, otherwise the number of failed jobs (capped at 255).

run_parallel() {
  local max="$1"; shift
  local fn="$1"; shift
  if [ "$1" != "--" ]; then
    log_error "run_parallel: missing -- separator"
    return 2
  fi
  shift
  local n=0 fails=0 pids=() pidx_to_arg=()
  for arg in "$@"; do
    # shellcheck disable=SC2086
    ( "$fn" "$arg" ) &
    pids+=($!)
    pidx_to_arg+=("$arg")
    n=$((n+1))
    if [ "$n" -ge "$max" ]; then
      # wait for any one to finish before launching more
      if ! wait -n 2>/dev/null; then
        # bash <4.3 fallback: wait for all then break out
        for p in "${pids[@]}"; do wait "$p" || fails=$((fails+1)); done
        pids=(); n=0
      else
        n=$((n-1))
      fi
    fi
  done
  for p in "${pids[@]}"; do
    if ! wait "$p"; then fails=$((fails+1)); fi
  done
  [ "$fails" -gt 255 ] && fails=255
  return "$fails"
}
