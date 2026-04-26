# Method: `login-item` (macOS)

Adds an entry to System Events Login Items via `osascript` so the app
appears in `System Settings -> General -> Login Items`. Visually
identical to dragging an app into that list by hand.

## How it's added

```osascript
tell application "System Events"
  make login item at end with properties \
    {path:"<path>", hidden:false, name:"com.lovable-startup.<name>"}
end tell
```

The login item's `name` carries the `com.lovable-startup.` prefix so
`list` and `remove` can find it deterministically.

## When it runs

At GUI login, after `loginwindow` finishes. The Dock launches the app
the same way it would for a user-added item.

## Best for

- GUI apps that need to register with the Dock or use Apple Events
  (Spotify, Slack, Notion-style apps).
- Cases where the user wants to see and toggle the entry in the
  standard System Settings panel.

## Gotchas

- macOS Ventura+ asks for explicit permission the first time
  (Background Items dialog). The script can't bypass it — the user
  must click "Allow".
- Sandboxed apps cannot add login items for themselves; this script
  is unsandboxed (raw `osascript`) so it works.
- `osascript` may prompt for Automation permission for "System Events"
  on the first run.
- Not available on Linux. `64` skips this method silently when
  `osascript` isn't on `$PATH`.

## Verify manually

```bash
osascript -e 'tell application "System Events" to get the name of every login item'
# Or open System Settings -> General -> Login Items
```

## Remove

```bash
./run.sh -I 64 -- remove <name> --method login-item
```

Calls `delete login item "com.lovable-startup.<name>"` via osascript.
Idempotent — missing items return 0.