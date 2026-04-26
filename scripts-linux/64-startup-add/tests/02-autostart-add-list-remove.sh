#!/usr/bin/env bash
set -u
. "$(dirname "$0")/_framework.sh"
TF_NAME="02-autostart-add-list-remove"
tf_setup

# Add via autostart (Linux GUI default).
tf_run_quiet app /usr/bin/echo --name hello-auto --method autostart
f="$XDG_CONFIG_HOME/autostart/lovable-startup-hello-auto.desktop"
assert_file "$f" "autostart .desktop is created"

out=$(tf_run list 2>&1)
assert_contains 'autostart' "$out" "list shows autostart row"
assert_contains 'hello-auto' "$out" "list shows entry name"

# Plant a foreign .desktop -- must NOT be listed or touched.
foreign="$XDG_CONFIG_HOME/autostart/firefox.desktop"
printf '[Desktop Entry]\nName=Firefox\nExec=firefox\n' > "$foreign"
out=$(tf_run list 2>&1)
assert_not_contains 'firefox' "$out" "foreign firefox.desktop is not listed"

# Remove the tool entry; foreign survives.
tf_run_quiet remove hello-auto --method autostart
assert_no_file "$f"       "autostart entry removed"
assert_file    "$foreign" "foreign firefox.desktop still exists"

# Idempotent re-remove: exit 0, warning only.
tf_run_quiet remove hello-auto --method autostart; rc=$?
assert_exit 0 "$rc" "second remove is no-op exit 0"

tf_teardown
tf_summary