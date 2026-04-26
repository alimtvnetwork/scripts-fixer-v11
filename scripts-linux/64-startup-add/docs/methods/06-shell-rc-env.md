# Method: `shell-rc-env` (Linux + macOS)

Persists `KEY=VALUE` environment variables in the user's interactive
shell rc file inside a single shared marker block. All env vars added
via `64 env ...` live in the same block so listing and pruning are
deterministic.

## Path

- macOS (zsh): `~/.zshrc`
- Linux (bash): `~/.bashrc`
- Override via `$SHELL`. Detection: `helpers/detect.sh::detect_shell_rc`.

## Block shape

```bash
# >>> lovable-startup-env (managed) >>>
export EDITOR='nvim'
export PATH_EXTRA='/opt/bin:/usr/local/bin'
export NOTE='it'\''s fine'
# <<< lovable-startup-env <<<
```

Values are wrapped in **single quotes** with the `'\''` idiom so spaces,
`:`, `&`, `$`, and embedded single quotes survive sourcing. We never
use `printf %q` here — it produced strings that broke when re-injected
via `awk -v`.

## When it applies

Every interactive shell start. For non-interactive contexts (cron,
systemd services, GUI app launches), use the OS-native env method:

- Linux: `systemctl --user set-environment KEY=VALUE` (volatile).
- macOS: `launchctl setenv KEY VALUE` — see `--method launchctl`.

## Best for

`PATH` extensions, editor preferences, language tool versions
(`JAVA_HOME`, `GOPATH`), API base URLs, theme variables.

## Gotchas

- Only loaded by interactive shells. A GUI app launched from
  Spotlight/Dock will NOT see these vars. Pair with `launchctl` on
  macOS for full coverage.
- Re-adding the same key **upserts** the value (the export line is
  removed and re-appended); siblings are preserved.
- Removing the last key in the block also drops the markers, so the
  rc file doesn't accumulate empty marker pairs.

## Verify manually

```bash
grep -F 'lovable-startup-env' ~/.bashrc ~/.zshrc 2>/dev/null
# Open a new shell:
printenv EDITOR PATH_EXTRA
```

## Remove

```bash
# One specific KEY:
./run.sh -I 64 -- remove EDITOR --method shell-rc-env

# All managed env vars (block disappears entirely):
./run.sh -I 64 -- list                # see what's there
./run.sh -I 64 -- prune --dry-run     # preview
./run.sh -I 64 -- prune --yes         # sweep
```

Idempotent. Removing the last key strips both markers cleanly.