#!/usr/bin/env bash
set -u
. "$(dirname "$0")/_framework.sh"
TF_NAME="06-prune"
tf_setup

# Plant entries across multiple methods.
tf_run_quiet app /usr/bin/echo --name a --method autostart
tf_run_quiet app /usr/bin/echo --name b --method shell-rc
tf_run_quiet env "K1=v1" --method shell-rc

# And a foreign file that prune must NOT touch.
foreign="$XDG_CONFIG_HOME/autostart/spotify.desktop"
printf '[Desktop Entry]\nName=Spotify\n' > "$foreign"

# --dry-run should show all 3 entries but change nothing.
out=$(tf_run prune --dry-run 2>&1); rc=$?
assert_exit 0 "$rc" "prune --dry-run exits 0"
assert_contains 'PRUNE PREVIEW' "$out"  "dry-run shows preview header"
assert_contains 'autostart'     "$out"  "dry-run lists autostart"
assert_contains 'shell-rc-app'  "$out"  "dry-run lists shell-rc-app"
assert_contains 'shell-rc-env'  "$out"  "dry-run lists shell-rc-env"
assert_file "$XDG_CONFIG_HOME/autostart/lovable-startup-a.desktop" "dry-run did not delete autostart"

# Real prune.
tf_run_quiet prune --yes
assert_no_file "$XDG_CONFIG_HOME/autostart/lovable-startup-a.desktop" "autostart removed"
rc_file="$HOME/.bashrc"
content=$(cat "$rc_file")
assert_not_contains 'lovable-startup-b'   "$content" "shell-rc app block gone"
assert_not_contains 'lovable-startup-env' "$content" "shell-rc env block gone"
assert_file "$foreign" "foreign Spotify .desktop preserved"

# Idempotent: prune again on empty home.
out=$(tf_run prune --yes 2>&1); rc=$?
assert_exit 0 "$rc" "prune on empty home exits 0"
assert_contains 'nothing to remove' "$out" "prune reports empty"

tf_teardown
tf_summary