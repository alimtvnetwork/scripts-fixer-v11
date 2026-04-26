#!/usr/bin/env bash
# Runs every numbered test in this directory.
# Each test is an isolated bash script; failures don't stop the suite.
set -u
SUITE_DIR="$(cd "$(dirname "$0")" && pwd)"

RED=$'\e[31m'; GRN=$'\e[32m'; YEL=$'\e[33m'; CYAN=$'\e[36m'; DIM=$'\e[2m'; RST=$'\e[0m'
[ -t 1 ] || { RED=""; GRN=""; YEL=""; CYAN=""; DIM=""; RST=""; }

printf '%s========================================%s\n' "$CYAN" "$RST"
printf '%s  64-startup-add :: test suite%s\n'           "$CYAN" "$RST"
printf '%s  uname=%s shell=%s%s\n'                      "$DIM" "$(uname -s)" "${SHELL:-?}" "$RST"
printf '%s========================================%s\n' "$CYAN" "$RST"

pass=0; fail=0; total=0
for t in "$SUITE_DIR"/[0-9]*.sh; do
  [ -f "$t" ] || continue
  total=$((total+1))
  if bash "$t"; then pass=$((pass+1))
  else fail=$((fail+1)); fi
  printf '\n'
done

printf '%s========================================%s\n' "$CYAN" "$RST"
if [ "$fail" -eq 0 ]; then
  printf '%s  ALL %d TEST FILES PASSED%s\n' "$GRN" "$total" "$RST"
  printf '%s========================================%s\n' "$CYAN" "$RST"
  exit 0
else
  printf '%s  %d/%d test files failed%s\n' "$RED" "$fail" "$total" "$RST"
  printf '%s========================================%s\n' "$CYAN" "$RST"
  exit 1
fi