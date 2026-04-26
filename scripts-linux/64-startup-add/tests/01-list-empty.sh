#!/usr/bin/env bash
# list on an empty sandbox: must succeed and report 0 entries.
set -u
. "$(dirname "$0")/_framework.sh"
TF_NAME="01-list-empty"
tf_setup

out=$(tf_run list 2>&1); rc=$?
assert_exit 0 "$rc" "list exits 0 on empty home"
assert_contains '0 entries tagged "lovable-startup"' "$out" "list reports 0 entries"
assert_not_contains 'autostart'    "$out" "no autostart row"
assert_not_contains 'shell-rc-app' "$out" "no shell-rc-app row"

tf_teardown
tf_summary