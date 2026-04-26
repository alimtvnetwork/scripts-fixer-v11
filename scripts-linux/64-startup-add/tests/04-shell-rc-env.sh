#!/usr/bin/env bash
set -u
. "$(dirname "$0")/_framework.sh"
TF_NAME="04-shell-rc-env"
tf_setup

rc_file="$HOME/.bashrc"
printf 'export USER_VAR=keep_me\n' > "$rc_file"

# Add 3 env vars including a tricky one.
tf_run_quiet env "EDITOR=nvim"                    --method shell-rc
tf_run_quiet env "PATH_EXTRA=/opt/bin:/usr/local/bin" --method shell-rc
tf_run_quiet env "NOTE=it's fine"                 --method shell-rc

content=$(cat "$rc_file")
assert_contains "export EDITOR='nvim'"     "$content" "EDITOR exported single-quoted"
assert_contains "/opt/bin:/usr/local/bin"  "$content" "colon-separated PATH preserved"
assert_contains "it'\\''s fine"            "$content" "embedded single quote escaped via '\\'' idiom"
assert_contains "USER_VAR=keep_me"         "$content" "user content preserved"

out=$(tf_run list 2>&1)
assert_contains 'shell-rc-env' "$out" "list shows env method"
assert_contains 'EDITOR'       "$out" "list shows EDITOR key"
assert_contains 'PATH_EXTRA'   "$out" "list shows PATH_EXTRA key"
assert_contains 'NOTE'         "$out" "list shows NOTE key"

# Remove one key -- block stays for siblings.
tf_run_quiet remove EDITOR --method shell-rc-env
content=$(cat "$rc_file")
assert_not_contains "export EDITOR=" "$content" "EDITOR removed"
assert_contains "PATH_EXTRA="        "$content" "siblings remain"
assert_contains '# >>> lovable-startup-env (managed) >>>' "$content" "block markers stay"

# Remove remaining keys -- block (and markers) must disappear entirely.
tf_run_quiet remove PATH_EXTRA --method shell-rc-env
tf_run_quiet remove NOTE       --method shell-rc-env
content=$(cat "$rc_file")
assert_not_contains 'lovable-startup-env' "$content" "markers gone after last key removed"
assert_contains "USER_VAR=keep_me"        "$content" "user content survives full env removal"

tf_teardown
tf_summary