# Method: `shell-rc` for apps (Linux + macOS)

Appends a marker-delimited block to the user's interactive shell rc file
(`~/.zshrc` on macOS / zsh users, `~/.bashrc` on Linux bash users).

## Path

- macOS default shell (zsh):  `~/.zshrc`
- Linux default shell (bash): `~/.bashrc`
- Detection: `helpers/detect.sh::detect_shell_rc` (honors `$SHELL`).

## Block shape

```bash
# >>> lovable-startup-<name> (lovable-startup-app) >>>
(<path> <args> &) >/dev/null 2>&1
# <<< lovable-startup-<name> <<<
```

The `(...&)` pattern double-forks so the rc file finishes sourcing
immediately (no UI freeze on terminal open).

## When it runs

Every time an interactive shell starts: every new terminal tab, every
`tmux` window, every SSH login. **Not** on cron or non-interactive
`bash -c` invocations.

## Best for

- Boxes with no systemd, no LaunchAgents, no DE.
- Per-shell tooling (tmux session managers, ssh-agent, gpg-agent).
- Quick try-out before committing to a "real" startup method.

## Gotchas

- Multiple terminals = multiple instances. If your app isn't safe to run
  twice, add a guard:
  ```bash
  pgrep -f myapp >/dev/null || (myapp &)
  ```
- `Exec` here goes through the user's shell, so `~`, `$VARS`, and
  globs **do** expand — opposite of `autostart` and `launchagent`.
- Doesn't run for non-interactive shells (cron jobs, `scp`, ...).

## Verify manually

```bash
grep -F 'lovable-startup-' ~/.bashrc ~/.zshrc 2>/dev/null
# Open a new terminal, then check that your app process is running.
```

## Remove

```bash
./run.sh -I 64 -- remove <name> --method shell-rc
```

Strips the marker pair and everything between them via `awk`. Other
content of the rc file is preserved byte-for-byte. Idempotent.