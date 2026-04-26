# Method: `launchagent` (macOS)

Writes a `launchd` user agent plist so the app starts at every user login
(and is restarted by `launchd` if it crashes). This is the macOS default.

## Path

```
~/Library/LaunchAgents/com.lovable-startup.<name>.plist
```

## Plist shape

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.lovable-startup.<name></string>
  <key>ProgramArguments</key>
  <array>
    <string><path></string>
    <string><arg1></string>
    ...
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><false/>
</dict>
</plist>
```

After write, `64` runs:

```
launchctl bootstrap "gui/$(id -u)" <plist>
```

## When it runs

At every user login (RunAtLoad=true). Set `KeepAlive=true` if you need
launchd to respawn the process on exit.

## Best for

Anything that needs to start with the GUI session and survive across
normal use: menu-bar apps, sync daemons, dev servers.

## Gotchas

- Plist string values are **XML-escaped via `sed`**, not bash
  parameter expansion (the latter mangled `<`/`>` inside `$()`).
- `ProgramArguments` is split on whitespace; quoting in `--args` is NOT
  honored. Pass a single shell wrapper if you need quoting.
- macOS Ventura+ may show a "Background Items Added" notification the
  first time and require the user to allow it in System Settings.
- LaunchAgents under `~/Library/LaunchAgents/` are user-scope. For
  system-scope (every user), put plists in `/Library/LaunchAgents/`
  with root ownership — out of scope for `64`.

## Verify manually

```bash
ls -la ~/Library/LaunchAgents/com.lovable-startup.*
launchctl list | grep lovable-startup
launchctl print "gui/$(id -u)/com.lovable-startup.<name>"
```

## Remove

```bash
./run.sh -I 64 -- remove <name> --method launchagent
```

`64` runs `launchctl bootout` before deleting the plist. Idempotent.