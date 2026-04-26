# Method: `autostart` (Linux)

Writes a freedesktop.org `.desktop` file under XDG autostart so the user's
desktop environment (GNOME, KDE, XFCE, Cinnamon, MATE, LXQt, ...) launches
the app at graphical login.

## Path

```
${XDG_CONFIG_HOME:-$HOME/.config}/autostart/lovable-startup-<name>.desktop
```

## Layout

```ini
[Desktop Entry]
Type=Application
Name=<name>
Exec=<path> <args>
X-GNOME-Autostart-enabled=true
```

## When it runs

At graphical session start (after login, after `gnome-session` /
`plasma-session` is up). Does **not** run on tty-only logins or over
SSH-without-DISPLAY.

## Best for

GUI apps that need an X/Wayland session (status indicators, tray apps,
sync clients, ...). It's the default on a Linux box where `$DISPLAY` or
`$WAYLAND_DISPLAY` is set.

## Gotchas

- WSL2 without WSLg has no `$DISPLAY` -> `64` falls back to `systemd-user`.
- `Exec=` does **not** spawn a shell; pipes/redirects in `--args` won't
  expand. Wrap in `bash -lc '...'` if you need shell features.
- Some DEs (KDE) require `OnlyShowIn=` to scope to a specific desktop;
  we omit it so the entry runs on every DE that honors XDG autostart.

## Verify manually

```bash
ls -la ~/.config/autostart/lovable-startup-*.desktop
# Log out and back in, then check that your app process is running.
```

## Remove

```bash
./run.sh -I 64 -- remove <name> --method autostart
```

Removes the single `.desktop` file. Idempotent — re-running prints a
`not found` warn and exits 0.