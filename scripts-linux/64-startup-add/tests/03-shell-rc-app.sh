#!/usr/bin/env bash
set -u
. "$(dirname "$0")/_framework.sh"
TF_NAME="03-shell-rc-app"
tf_setup

rc_file="$HOME/.bashrc"
# Seed user content that MUST survive every operation.
printf '# user-content-line-1\nalias ll="ls -la"\n' > "$rc_file"

tf_run_quiet app /usr/bin/echo --name myapp --method shell-rc
content=$(cat "$rc_file")
assert_contains '# >>> lovable-startup-myapp (lovable-startup-app) >>>' "$content" "open marker present"
assert_contains '# <<< lovable-startup-myapp <<<'                       "$content" "close marker present"
assert_contains 'alias ll="ls -la"' "$content" "user content preserved after add"

# list shows it.
out=$(tf_run list 2>&1)
assert_contains 'shell-rc-app' "$out" "list shows shell-rc-app"
assert_contains 'myapp'        "$out" "list shows app name"

# remove strips both markers and content between, keeps user lines.
tf_run_quiet remove myapp --method shell-rc
content=$(cat "$rc_file")
assert_not_contains 'lovable-startup-myapp' "$content" "markers removed"
assert_contains 'alias ll="ls -la"' "$content" "user content survives remove"

tf_teardown
tf_summary