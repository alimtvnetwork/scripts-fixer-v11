# 64-startup-add :: tests

Self-contained black-box tests for the `app | env | list | remove | prune`
subverbs. Each test sandboxes everything under a temporary `$HOME` so it
can't touch your real autostart files, shell rc, or LaunchAgents.

## Run

```bash
bash scripts-linux/64-startup-add/tests/run-all.sh
```

Or run a single test:

```bash
bash scripts-linux/64-startup-add/tests/03-shell-rc-app.sh
```

## What's covered

| File | Method(s) covered | Linux | macOS |
|------|-------------------|-------|-------|
| `01-list-empty.sh`               | `list` on empty $HOME            | ✓ | ✓ |
| `02-autostart-add-list-remove.sh`| `autostart` + foreign-file safety | ✓ | (n/a) |
| `03-shell-rc-app.sh`             | `shell-rc` app block, marker strip | ✓ | ✓ |
| `04-shell-rc-env.sh`             | env upsert, single-quote escaping, empty-block cleanup | ✓ | ✓ |
| `05-remove-safety.sh`            | path-traversal & empty-name rejection | ✓ | ✓ |
| `06-prune.sh`                    | dry-run + sweep across 3 methods, foreign-file safety | ✓ | ✓ |
| `07-systemd-user-unit.sh`        | unit file shape + list/remove     | ✓ | (skip) |
| `08-launchagent-plist.sh`        | plist shape + list/remove         | (skip) | ✓ |

## Conventions

- Tests source `_framework.sh`, which provides `tf_setup`, `tf_teardown`,
  `tf_run`, and the assertion helpers (`assert_eq`, `assert_contains`,
  `assert_file`, `assert_no_file`, `assert_exit`, `assert_not_contains`).
- `tf_setup` creates a fresh `$HOME` and `$XDG_CONFIG_HOME` per test.
- A test file is considered passing when its `tf_summary` returns 0
  (zero failed assertions).
- macOS-only / Linux-only tests guard on `uname -s` and self-skip with a
  yellow `SKIP` line so the suite stays green on the other OS.

## CI hint

`run-all.sh` exits non-zero if any test file fails, so it drops into a
CI step verbatim:

```yaml
- name: 64-startup-add tests
  run: bash scripts-linux/64-startup-add/tests/run-all.sh
```