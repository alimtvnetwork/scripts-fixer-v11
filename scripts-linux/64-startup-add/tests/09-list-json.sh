#!/usr/bin/env bash
# Verify `list --json` emits valid JSON with the documented schema.
set -u
. "$(dirname "$0")/_framework.sh"
TF_NAME="09-list-json"
tf_setup

# 1. Empty home -> valid JSON with count=0 and entries=[].
out=$(tf_run list --json 2>/dev/null); rc=$?
assert_exit 0 "$rc" "list --json on empty home exits 0"
assert_contains '"count": 0' "$out" "empty: count=0"
assert_contains '"entries": []' "$out" "empty: entries=[]"
# Validate it's parseable JSON if python3 is available.
if command -v python3 >/dev/null 2>&1; then
  if printf '%s' "$out" | python3 -c 'import sys,json; json.load(sys.stdin)' 2>/dev/null
  then _tf_pass "empty payload is valid JSON"
  else _tf_fail "empty payload is valid JSON" "valid JSON" "$out"; fi
fi

# 2. Plant entries across 3 methods + a foreign file -> populated JSON.
tf_run_quiet app /usr/bin/echo --name a --method autostart
tf_run_quiet app /usr/bin/echo --name b --method shell-rc
tf_run_quiet env "K=v" --method shell-rc
printf '[Desktop Entry]\nName=Foreign\n' > "$XDG_CONFIG_HOME/autostart/foreign.desktop"

out=$(tf_run list --json 2>/dev/null); rc=$?
assert_exit 0 "$rc" "list --json with entries exits 0"
assert_contains '"count": 3'         "$out" "count reflects 3 tagged entries"
assert_contains '"method": "autostart"'    "$out" "autostart entry present"
assert_contains '"method": "shell-rc-app"' "$out" "shell-rc-app entry present"
assert_contains '"method": "shell-rc-env"' "$out" "shell-rc-env entry present"
assert_contains '"name": "a"'        "$out" "name a present"
assert_contains '"name": "K"'        "$out" "env key K present"
assert_contains '"scope": "user"'    "$out" "scope present"
assert_not_contains 'foreign'        "$out" "foreign .desktop excluded from JSON"

if command -v python3 >/dev/null 2>&1; then
  # Round-trip through python and verify the structure programmatically.
  parsed=$(printf '%s' "$out" | python3 -c '
import sys, json
d = json.load(sys.stdin)
print(d["count"], len(d["entries"]), d["tag"])
')
  assert_eq "3 3 lovable-startup" "$parsed" "JSON parses with count=3, entries=3, tag=lovable-startup"
fi

# 3. --format=json works as alias for --json.
out=$(tf_run list --format=json 2>/dev/null)
assert_contains '"count": 3' "$out" "--format=json works"

# 4. --format=table is the explicit default.
out=$(tf_run list --format=table 2>/dev/null)
assert_contains 'METHOD' "$out" "--format=table prints header"

tf_teardown
tf_summary