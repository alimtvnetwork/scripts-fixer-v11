# Method: `systemd-user` (Linux)

Writes a `systemd --user` unit so the app starts at user login (or at
boot, with linger enabled). This is the right method on headless servers,
containers, and WSL where there's no graphical session.

## Path

```
${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/lovable-startup-<name>.service
```

## Unit shape

```ini
[Unit]
Description=lovable-startup <name>
After=default.target

[Service]
Type=simple
ExecStart=<path> <args>
Restart=on-failure

[Install]
WantedBy=default.target
```

After write, `64` runs:

```
systemctl --user daemon-reload
systemctl --user enable --now lovable-startup-<name>.service
```

## When it runs

At the user's first login on this machine (PAM `pam_systemd` opens the
user manager). With linger, it runs at boot independently of any login.

## Best for

- Headless servers / VMs / containers without an X server.
- WSL2 (with `systemd=true` in `/etc/wsl.conf`).
- Long-running background processes that need restart-on-failure.

## Headless: keep running after logout

```bash
STARTUP_LINGER=1 ./run.sh -I 64 -- app /usr/local/bin/myd \
  --name myd --method systemd-user
```

`64` calls `loginctl enable-linger $USER` so the user manager (and your
service) survives logout.

## Gotchas

- Requires systemd as PID 1; raw `runit`/`openrc`/`busybox-init` boxes
  must use `shell-rc` instead.
- WSL1 has no systemd at all.
- `Type=simple` expects the binary to **stay in the foreground**.
  Daemonizing apps (e.g. `apachectl start`) need `Type=forking`.

## Verify manually

```bash
systemctl --user list-unit-files 'lovable-startup-*'
systemctl --user status   lovable-startup-<name>
journalctl --user -u      lovable-startup-<name> -n 50
```

## Remove

```bash
./run.sh -I 64 -- remove <name> --method systemd-user
```

`64` runs `disable` + `stop` before deleting the unit file, then
`daemon-reload`. Idempotent.