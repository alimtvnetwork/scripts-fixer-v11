<!-- spec-header:v1 -->
<div align="center">

<img src="../assets/icon-v1-rocket-stack.svg" alt="VS Code Context-Menu Fix" width="128" height="128"/>

# VS Code Windows Context-Menu Fix

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-10-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.72.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*User-facing companion to [spec/10-vscode-context-menu-fix](../spec/10-vscode-context-menu-fix/readme.md).*

</div>

---

## Overview

Restores or repairs the **"Open with Code"** entry on the Windows Explorer
right-click menu (file, directory, and directory background targets) when the
VS Code installer didn't register it, when a portable install is in use, or
when the entries point at a stale path.

This guide is the **operator's manual** for the fix. The full design contract,
registry-path tables, and machine-readable assertions live in the
[spec](../spec/10-vscode-context-menu-fix/readme.md).

> 🛡️ **Safety stance**: This page only describes operations against the
> per-user registry hive (`HKCU\Software\Classes`). No machine-wide
> (`HKLM` / `HKCR`) writes are required to repair a per-user VS Code install,
> and admin elevation is **not** needed for the safe-test workflow below.

---

## Prerequisites

| Requirement | Why it matters |
|-------------|----------------|
| Windows 10 (1809+) or Windows 11 | Explorer context-menu surface this fix targets. |
| PowerShell **5.1+** or PowerShell 7 | Script uses `New-Item`, `Set-ItemProperty`, `reg.exe export`. |
| VS Code installed (any edition: Stable / Insiders / VSCodium) | The script writes a command line that points at `Code.exe` — it must exist on disk. |
| Read access to `HKCU\Software\Classes` | Always granted for the current user. |
| `reg.exe` on `PATH` | Used for the automatic `.reg` backup. Ships with Windows. |
| Repo cloned locally | Needed to invoke `.\run.ps1 -I 10`. |

### Pre-flight check

Run this before applying the fix — it tells you which `Code.exe` will be
wired into the menu, and confirms the current state of the relevant keys:

```powershell
# From the repo root
.\run.ps1 -I 10 doctor
```

The `doctor` subcommand prints:

1. The detected `Code.exe` path (per-user, system, or portable).
2. The current `(Default)` value of each affected key, if present.
3. Any orphan / mismatched entries the fix would replace.

If `doctor` reports **"Code.exe not found"**, install or re-install VS Code
first — the fix will refuse to wire the menu to a non-existent target.

---

## Safe test mode (HKCU sandbox)

The script's safe mode writes **only** under
`HKCU\Software\Classes\…` — never under `HKLM` or the merged `HKCR` view.
This means:

- No admin elevation required.
- Changes apply to the current Windows user only.
- A reboot or sign-out is **not** needed; Explorer picks up `HKCU` changes
  the next time you open a context menu.
- Other users on the machine are unaffected.

### Run the test

```powershell
# Per-user, sandboxed install (default). Emits an automatic .reg backup
# before any write — see "Rollback" below.
.\run.ps1 -I 10 install -Scope CurrentUser
```

### Verify

```powershell
# Read-only assertion pass — no writes
.\run.ps1 -I 10 verify

# Or inspect the keys directly
reg query "HKCU\Software\Classes\*\shell\VSCode" /s
reg query "HKCU\Software\Classes\Directory\shell\VSCode" /s
reg query "HKCU\Software\Classes\Directory\Background\shell\VSCode" /s
```

You should see, for each of the three targets:

- A `VSCode` subkey whose `(Default)` is the menu label (e.g. `Open with Code`).
- A `command` subkey whose `(Default)` is the full quoted `Code.exe` path
  followed by the appropriate placeholder (`"%1"` for files/dirs, `"%V"` for
  the directory-background target).

### Smoke test

1. Open Explorer.
2. Right-click any file → confirm **"Open with Code"** appears.
3. Right-click any folder → confirm the entry appears.
4. Right-click the empty area inside an open folder → confirm the entry
   appears (this exercises the `Directory\Background` target).

Click each one once to confirm it actually launches the expected `Code.exe`.

---

## Rollback

Every `install` run automatically exports the affected keys **before**
writing, so you always have a one-command undo.

### Where the backup lives

```
.resolved/10-vscode-context-menu-fix/backups/
    backup-2026-04-22_14-30-05.reg
    backup-2026-04-22_15-12-40.reg
    …
```

The filename is a UTC-ish local timestamp (`yyyy-MM-dd_HH-mm-ss`). The most
recent backup is also symlinked / copied to `latest.reg` in the same folder
for convenience.

### Option 1 — Restore the backup file

```powershell
# Restore the most recent pre-change snapshot
reg import .\.resolved\10-vscode-context-menu-fix\backups\latest.reg

# Or pick a specific timestamp
reg import .\.resolved\10-vscode-context-menu-fix\backups\backup-2026-04-22_14-30-05.reg
```

`reg import` is idempotent and only touches the keys captured in the
snapshot. Because the snapshot was taken from `HKCU\Software\Classes`, the
restore is also per-user and needs no elevation.

### Option 2 — Use the dispatcher's uninstall verb

```powershell
.\run.ps1 -I 10 uninstall -Scope CurrentUser
```

This removes the `VSCode` subkeys this script created under each of the
three target paths. It does **not** touch keys it didn't create (e.g. an
unrelated `Open with Sublime` entry).

### Option 3 — Restore script

A standalone restore helper is shipped at:

```
scripts/10-vscode-context-menu-fix/helpers/restore-from-backup.ps1
```

```powershell
# Interactive — lists every backup in the folder and lets you pick one
.\scripts\10-vscode-context-menu-fix\helpers\restore-from-backup.ps1

# Non-interactive — restore latest
.\scripts\10-vscode-context-menu-fix\helpers\restore-from-backup.ps1 -Latest
```

### Verifying the rollback

```powershell
.\run.ps1 -I 10 verify -ExpectAbsent
```

`-ExpectAbsent` flips the assertion polarity: the run passes only if **no**
`VSCode` subkey is present under any of the three targets.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Menu entry missing after install | Explorer cached the old menu. | Sign out + back in, or restart `explorer.exe`. |
| Entry launches the wrong `Code.exe` | Multiple editions installed. | Re-run with `-Edition stable` / `-Edition insiders`. |
| `Access is denied` writing `HKCU` | Roaming-profile lock or AV. | Close Explorer windows, retry; verify AV isn't blocking `reg.exe`. |
| Backup folder empty after install | Run was a `-WhatIf` preview. | Re-run without `-WhatIf` to produce a real backup. |
| Want machine-wide install | Out of scope for this guide. | See [spec/10-vscode-context-menu-fix](../spec/10-vscode-context-menu-fix/readme.md) §"Machine scope". |

---

## See also

- [Spec — design contract](../spec/10-vscode-context-menu-fix/readme.md)
- [Script 10 implementation folder](../scripts/10-vscode-context-menu-fix/readme.md)
- [Spec writing guide](../spec/00-spec-writing-guide/readme.md)
- [Changelog](../changelog.md)

---

<!-- spec-footer:v1 -->

## Author

<div align="center">

### [Md. Alim Ul Karim](https://www.google.com/search?q=alim+ul+karim)

**[Creator & Lead Architect](https://alimkarim.com)** | [Chief Software Engineer](https://www.google.com/search?q=alim+ul+karim), [Riseup Asia LLC](https://riseup-asia.com)

</div>

A system architect with **20+ years** of professional software engineering experience across enterprise, fintech, and distributed systems.

| | |
|---|---|
| **Website** | [alimkarim.com](https://alimkarim.com/) |
| **LinkedIn** | [linkedin.com/in/alimkarim](https://linkedin.com/in/alimkarim) |
| **Role** | Chief Software Engineer, [Riseup Asia LLC](https://riseup-asia.com) |

### Riseup Asia LLC — Top Software Company in Wyoming, USA

[Riseup Asia LLC](https://riseup-asia.com) is a top-leading software company headquartered in Wyoming, USA, specializing in enterprise-grade frameworks, research-based AI models, and distributed systems architecture.

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](../LICENSE) file for the full text.

```
Copyright (c) 2026 Alim Ul Karim
```

---

<div align="center">

*Part of the Dev Tools Setup Scripts toolkit — see the [spec writing guide](../spec/00-spec-writing-guide/readme.md) for the full readme contract.*

</div>
