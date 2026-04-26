#!/usr/bin/env bash
# Minimal test framework for 64-startup-add.
# Each test file is a bash script that sources this and calls
#   tf_setup        # creates a sandboxed $HOME under /tmp
#   tf_teardown     # removes it
#   assert_eq       <expected> <actual> <label>
#   assert_contains <needle>   <haystack> <label>
#   assert_file     <path>     <label>
#   assert_no_file  <path>     <label>
#   assert_exit     <expected-code> <actual-code> <label>
# and prints a single PASS / FAIL line per assertion.

TF_PASS=0
TF_FAIL=0
TF_NAME="${TF_NAME:-$(basename "${BASH_SOURCE[1]:-test}" .sh)}"

# Resolve repo paths once.
TF_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_SCRIPT_DIR="$(cd "$TF_TESTS_DIR/.." && pwd)"
TF_RUN="$TF_SCRIPT_DIR/run.sh"

# Color helpers (ANSI; degraded gracefully on non-TTY).
if [ -t 1 ]; then
  TF_RED=$'\e[31m'; TF_GRN=$'\e[32m'; TF_YEL=$'\e[33m'; TF_DIM=$'\e[2m'; TF_RST=$'\e[0m'
else
  TF_RED=""; TF_GRN=""; TF_YEL=""; TF_DIM=""; TF_RST=""
fi

_tf_pass() { TF_PASS=$((TF_PASS+1)); printf '  %sPASS%s %s\n' "$TF_GRN" "$TF_RST" "$1"; }
_tf_fail() {
  TF_FAIL=$((TF_FAIL+1))
  printf '  %sFAIL%s %s\n' "$TF_RED" "$TF_RST" "$1"
  [ -n "${2:-}" ] && printf '       %sexpected:%s %s\n' "$TF_DIM" "$TF_RST" "$2"
  [ -n "${3:-}" ] && printf '       %s     got:%s %s\n' "$TF_DIM" "$TF_RST" "$3"
}

tf_setup() {
  TF_HOME="$(mktemp -d -t lov64-XXXXXX)"
  export HOME="$TF_HOME"
  export XDG_CONFIG_HOME="$TF_HOME/.config"
  # Default to bash on Linux test runs so detect_shell_rc -> ~/.bashrc.
  export SHELL="${SHELL:-/bin/bash}"
  mkdir -p "$XDG_CONFIG_HOME"
  touch "$TF_HOME/.bashrc" "$TF_HOME/.zshrc"
  printf '%s===== %s =====%s\n' "$TF_YEL" "$TF_NAME" "$TF_RST"
}

tf_teardown() {
  if [ -n "${TF_HOME:-}" ] && [ -d "$TF_HOME" ]; then
    rm -rf "$TF_HOME"
  fi
}

tf_summary() {
  local total=$((TF_PASS + TF_FAIL))
  if [ "$TF_FAIL" -eq 0 ]; then
    printf '  %s%d/%d passed%s\n' "$TF_GRN" "$TF_PASS" "$total" "$TF_RST"
    return 0
  fi
  printf '  %s%d/%d passed (%d failed)%s\n' "$TF_RED" "$TF_PASS" "$total" "$TF_FAIL" "$TF_RST"
  return 1
}

# ---- assertions ----

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  if [ "$expected" = "$actual" ]; then _tf_pass "$label"
  else _tf_fail "$label" "$expected" "$actual"; fi
}

assert_contains() {
  local needle="$1" haystack="$2" label="$3"
  case "$haystack" in
    *"$needle"*) _tf_pass "$label" ;;
    *)           _tf_fail "$label" "contains: $needle" "$haystack" ;;
  esac
}

assert_not_contains() {
  local needle="$1" haystack="$2" label="$3"
  case "$haystack" in
    *"$needle"*) _tf_fail "$label" "absent: $needle" "$haystack" ;;
    *)           _tf_pass "$label" ;;
  esac
}

assert_file() {
  local path="$1" label="$2"
  if [ -f "$path" ]; then _tf_pass "$label"
  else _tf_fail "$label" "file exists: $path" "missing"; fi
}

assert_no_file() {
  local path="$1" label="$2"
  if [ ! -e "$path" ]; then _tf_pass "$label"
  else _tf_fail "$label" "absent: $path" "still present"; fi
}

assert_exit() {
  local expected="$1" actual="$2" label="$3"
  if [ "$expected" = "$actual" ]; then _tf_pass "$label"
  else _tf_fail "$label" "exit=$expected" "exit=$actual"; fi
}

# Convenience: invoke the script under test against the sandbox HOME.
tf_run() { bash "$TF_RUN" "$@"; }
tf_run_quiet() { bash "$TF_RUN" "$@" >/dev/null 2>&1; }