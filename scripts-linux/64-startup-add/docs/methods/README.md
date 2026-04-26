# Per-method documentation

Each file describes one of the six startup-registration methods that
`64-startup-add` supports. Read the file for the method you're using
to understand exactly where the entry lands, when it runs, and what
gotchas to expect.

| File | Method | OS | Default? |
|------|--------|-----|---------|
| [01-autostart.md](01-autostart.md)         | `autostart`     | Linux GUI       | yes |
| [02-systemd-user.md](02-systemd-user.md)   | `systemd-user`  | Linux headless  | yes |
| [03-shell-rc-app.md](03-shell-rc-app.md)   | `shell-rc` (app)| Linux + macOS   | no  |
| [04-launchagent.md](04-launchagent.md)     | `launchagent`   | macOS           | yes |
| [05-login-item.md](05-login-item.md)       | `login-item`    | macOS           | no  |
| [06-shell-rc-env.md](06-shell-rc-env.md)   | `shell-rc-env`  | Linux + macOS   | yes (env) |

All methods follow the same conventions:

- Files / labels carry the `lovable-startup` tag prefix so `list`,
  `remove`, and `prune` can find them without false positives.
- Every write is idempotent: re-running an `app add` removes the old
  artifact first.
- File errors call `log_file_error <path> <reason>` (CODE RED rule),
  so failures always tell you the exact path and why.

See [`tests/`](../../tests/) for the automated harness that exercises
each method end-to-end.