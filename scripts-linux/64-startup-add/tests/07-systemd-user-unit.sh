#!/usr/bin/env bash
# Validates the systemd-user unit file shape WITHOUT requiring systemd
# to be running (we only check that the file is written correctly and
# `list`/`remove` find it). Skipped on macOS.
set -u
. "$(dirname "$0")/_framework.sh"
TF_NAME="07-systemd-user-unit"

if [ "$(uname -s)" = "Darwin" ]; then
  printf '%s===== %s =====%s\n  %sSKIP%s macOS has no systemd-user\n' \
    "$TF_YEL" "$TF_NAME" "$TF_RST" "$TF_YEL" "$TF_RST"
  exit 0
fi

tf_setup

# Force the unit-write path (helpers may try systemctl; that's fine -- it
# just no-ops in containers without --user bus and the file should still land).
tf_run_quiet app /usr/bin/sleep --name sleeper --method systemd-user --args "3600"

unit="$XDG_CONFIG_HOME/systemd/user/lovable-startup-sleeper.service"
assert_file "$unit" "systemd-user unit file written"

content=$(cat "$unit" 2>/dev/null)
assert_contains 'Description=' "$content" "unit has Description="
assert_contains 'ExecStart='   "$content" "unit has ExecStart="
assert_contains 'WantedBy=default.target' "$content" "unit has WantedBy=default.target"

out=$(tf_run list 2>&1)
assert_contains 'systemd-user' "$out" "list shows systemd-user method"
assert_contains 'sleeper'      "$out" "list shows entry name"

tf_run_quiet remove sleeper --method systemd-user
assert_no_file "$unit" "unit file removed"

tf_teardown
tf_summary