#!/usr/bin/env bash
# macOS-only: validates the LaunchAgent plist shape, list, and remove.
# Skipped on Linux (no ~/Library/LaunchAgents convention; helpers gate
# on uname -s).
set -u
. "$(dirname "$0")/_framework.sh"
TF_NAME="08-launchagent-plist"

if [ "$(uname -s)" != "Darwin" ]; then
  printf '%s===== %s =====%s\n  %sSKIP%s LaunchAgent is macOS-only\n' \
    "$TF_YEL" "$TF_NAME" "$TF_RST" "$TF_YEL" "$TF_RST"
  exit 0
fi

tf_setup
mkdir -p "$HOME/Library/LaunchAgents"

tf_run_quiet app /usr/bin/true --name unit-test --method launchagent
plist="$HOME/Library/LaunchAgents/com.lovable-startup.unit-test.plist"
assert_file "$plist" "LaunchAgent plist written"

content=$(cat "$plist" 2>/dev/null)
assert_contains '<key>Label</key>'           "$content" "plist has Label"
assert_contains 'com.lovable-startup.unit-test' "$content" "Label is tagged"
assert_contains '<key>ProgramArguments</key>' "$content" "plist has ProgramArguments"
assert_contains '<key>RunAtLoad</key>'        "$content" "plist has RunAtLoad"

out=$(tf_run list 2>&1)
assert_contains 'launchagent' "$out" "list shows launchagent method"
assert_contains 'unit-test'   "$out" "list shows entry name"

tf_run_quiet remove unit-test --method launchagent
assert_no_file "$plist" "LaunchAgent plist removed"

tf_teardown
tf_summary