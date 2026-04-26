#!/usr/bin/env bash
# Verify the interactive picker (selection parsing, range expansion, --yes).
# We can't drive a real TTY here, so we feed input via stdin (the helper
# falls through to plain `read` when /dev/tty isn't readable in CI).
set -u
. "$(dirname "$0")/_framework.sh"
TF_NAME="10-remove-interactive"
tf_setup

# Plant 4 entries so we can exercise selection forms.
tf_run_quiet app /usr/bin/echo --name a --method autostart
tf_run_quiet app /usr/bin/echo --name b --method autostart
tf_run_quiet app /usr/bin/echo --name c --method shell-rc
tf_run_quiet env "K1=v1" --method shell-rc

f_a="$XDG_CONFIG_HOME/autostart/lovable-startup-a.desktop"
f_b="$XDG_CONFIG_HOME/autostart/lovable-startup-b.desktop"
rc_file="$HOME/.bashrc"

assert_file "$f_a" "setup: entry a present"
assert_file "$f_b" "setup: entry b present"

# 1. "q" cancels: nothing removed.
out=$(printf 'q\n' | tf_run remove --interactive 2>&1)
assert_contains 'cancelled (no selection)' "$out" "q cancels picker"
assert_file "$f_a" "cancel: a still present"
assert_file "$f_b" "cancel: b still present"

# 2. Single index "1" + auto-confirm via --yes.
#    Snapshot is sorted by enumerator order (autostart first, then shell-rc).
#    Index 1 = first row -> entry "a" (autostart).
out=$(printf '1\n' | tf_run remove --interactive --yes 2>&1)
assert_contains 'interactive remove: 1 removed' "$out" "single pick removes 1"
assert_no_file "$f_a" "entry a removed"
assert_file    "$f_b" "entry b preserved"

# 3. Range "1-2" should hit the next two surviving rows (now b + c).
out=$(printf '1-2\n' | tf_run remove --interactive --yes 2>&1)
assert_contains 'interactive remove: 2 removed' "$out" "range 1-2 removes 2"
assert_no_file "$f_b" "entry b removed via range"
content=$(cat "$rc_file")
assert_not_contains 'lovable-startup-c' "$content" "shell-rc app block c gone"

# 4. Out-of-range token is warned + skipped (env var still present).
out=$(printf '99\n' | tf_run remove --interactive --yes 2>&1)
assert_contains 'no in-range selections' "$out" "99 out of range warns"
content=$(cat "$rc_file")
assert_contains 'export K1=' "$content" "env var still there after invalid pick"

# 5. "all" sweeps the rest.
out=$(printf 'all\n' | tf_run remove --interactive --yes 2>&1)
assert_contains 'interactive remove: 1 removed' "$out" "all removes remaining 1"
content=$(cat "$rc_file")
assert_not_contains 'lovable-startup-env' "$content" "env block fully gone"

# 6. Empty list -> graceful no-op.
out=$(tf_run remove --interactive --yes 2>&1)
assert_contains 'no entries to remove' "$out" "empty list reports no-op"

# 7. Comma + range mix "1,3" with method filter.
tf_run_quiet app /usr/bin/echo --name x --method autostart
tf_run_quiet app /usr/bin/echo --name y --method autostart
tf_run_quiet app /usr/bin/echo --name z --method autostart
out=$(printf '1,3\n' | tf_run remove --interactive --yes --method autostart 2>&1)
assert_contains 'interactive remove: 2 removed' "$out" "comma+method filter picks 2"
assert_no_file "$XDG_CONFIG_HOME/autostart/lovable-startup-x.desktop" "x removed"
assert_file    "$XDG_CONFIG_HOME/autostart/lovable-startup-y.desktop" "y preserved"
assert_no_file "$XDG_CONFIG_HOME/autostart/lovable-startup-z.desktop" "z removed"

tf_teardown
tf_summary