#!/usr/bin/env bash
# Exercise defense-in-depth in remove_startup_entry: path traversal,
# directory separators, empty names must be rejected before any file op.
set -u
. "$(dirname "$0")/_framework.sh"
TF_NAME="05-remove-safety"
tf_setup

# Plant a sensitive foreign file that the attack would target.
victim="$XDG_CONFIG_HOME/autostart/important.desktop"
mkdir -p "$(dirname "$victim")"
printf 'NEVER_DELETE\n' > "$victim"

# Attempt 1: path traversal name.
out=$(tf_run remove '../important' --method autostart 2>&1); rc=$?
assert_eq 1 "$rc" "traversal name rejected (exit 1)"
assert_file "$victim" "victim survives traversal attack"

# Attempt 2: directory separator.
out=$(tf_run remove 'foo/bar' --method autostart 2>&1); rc=$?
assert_eq 1 "$rc" "slash-name rejected (exit 1)"

# Attempt 3: empty name -- should error out before touching anything.
out=$(tf_run remove '' --method autostart 2>&1); rc=$?
# CLI parser logs "name required" and returns 1 before reaching the
# enumerate guard, so any non-zero exit is correct.
if [ "$rc" -ne 0 ]; then _tf_pass "empty name rejected (exit $rc)"
else _tf_fail "empty name rejected" "non-zero exit" "exit=$rc"; fi
assert_file "$victim" "victim survives empty-name attempt"

tf_teardown
tf_summary