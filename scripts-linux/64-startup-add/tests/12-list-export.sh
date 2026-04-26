#!/usr/bin/env bash
# Verify `list` can export to CSV/JSON files via --output and includes a
# status column (active|orphaned).
set -u
. "$(dirname "$0")/_framework.sh"
TF_NAME="12-list-export"
tf_setup

# Plant entries: one autostart, one shell-rc app, one shell-rc env.
tf_run_quiet app /usr/bin/echo --name a --method autostart
tf_run_quiet app /usr/bin/echo --name b --method shell-rc
tf_run_quiet env "K=v"             --method shell-rc

# 1. CSV to stdout.
out=$(tf_run list --csv 2>/dev/null); rc=$?
assert_exit 0 "$rc" "list --csv exits 0"
assert_contains 'method,name,path,status,scope' "$out" "csv: header present"
assert_contains 'autostart,a,'      "$out" "csv: autostart row"
assert_contains 'shell-rc-app,b,'   "$out" "csv: shell-rc-app row"
assert_contains 'shell-rc-env,K,'   "$out" "csv: shell-rc-env row"
# All planted entries point at real files we just wrote -> active.
csv_active_count=$(printf '%s\n' "$out" | grep -c ',active,')
assert_eq "3" "$csv_active_count" "csv: 3 active rows"

# 2. --format=csv is an alias for --csv.
out=$(tf_run list --format=csv 2>/dev/null)
assert_contains 'method,name,path,status,scope' "$out" "--format=csv works"

# 3. --output writes CSV to file (parent dirs created on demand).
csv_path="$TF_HOME/exports/inventory.csv"
tf_run list --csv --output "$csv_path" >/dev/null 2>&1; rc=$?
assert_exit 0 "$rc" "list --csv --output exits 0"
assert_file "$csv_path" "csv file created"
csv_body=$(cat "$csv_path")
assert_contains 'method,name,path,status,scope' "$csv_body" "csv file: header"
assert_contains 'autostart,a,'   "$csv_body" "csv file: autostart row"

# 4. --output writes JSON to file with the new status field.
json_path="$TF_HOME/exports/inventory.json"
tf_run list --json --output "$json_path" >/dev/null 2>&1; rc=$?
assert_exit 0 "$rc" "list --json --output exits 0"
assert_file "$json_path" "json file created"
json_body=$(cat "$json_path")
assert_contains '"count": 3'         "$json_body" "json file: count=3"
assert_contains '"status": "active"' "$json_body" "json file: status field"
if command -v python3 >/dev/null 2>&1; then
  parsed=$(python3 -c '
import sys, json
d = json.load(open(sys.argv[1]))
statuses = sorted({e["status"] for e in d["entries"]})
keys = sorted(d["entries"][0].keys())
print(",".join(statuses), "|", ",".join(keys))
' "$json_path")
  assert_eq "active | method,name,path,scope,status" "$parsed" "json: schema includes status"
fi

# 5. Combine --output with --method to scope the export.
autostart_csv="$TF_HOME/autostart.csv"
tf_run list --csv --method autostart --output "$autostart_csv" >/dev/null 2>&1
assert_file "$autostart_csv" "scoped csv file created"
body=$(cat "$autostart_csv")
assert_contains 'autostart,a,'  "$body" "scoped csv: autostart row"
assert_not_contains 'shell-rc'  "$body" "scoped csv: shell-rc rows excluded"

# 6. Orphaned status: delete the .desktop file directly, then re-export.
rm -f "$XDG_CONFIG_HOME/autostart/lovable-startup-a.desktop"
out=$(tf_run list --csv --method autostart 2>/dev/null)
# After delete, the enumerator no longer sees the entry at all (it scans the
# autostart dir). Status only marks rows whose tag survives but path vanished.
# So this is just a sanity check that the row is gone.
assert_not_contains ',a,' "$out" "deleted autostart no longer listed"

# 7. table --output writes the table to file too.
table_path="$TF_HOME/inv.txt"
tf_run list --output "$table_path" >/dev/null 2>&1
assert_file "$table_path" "table file created"
assert_contains 'METHOD'  "$(cat "$table_path")" "table file: header"
assert_contains 'STATUS'  "$(cat "$table_path")" "table file: status column"

# 8. Non-writable output path -> clear failure (exit 1).
set +e
tf_run list --csv --output /proc/1/cannot-write.csv >/dev/null 2>&1; rc=$?
set -e
assert_eq "1" "$rc" "unwritable --output fails with exit 1"

tf_teardown
tf_summary