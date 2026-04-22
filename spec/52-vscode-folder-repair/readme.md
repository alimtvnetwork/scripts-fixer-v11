<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 52 — Vscode Folder Repair" width="128" height="128"/>

# Spec 52 — Vscode Folder Repair

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-52-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: VS Code Folder-Only Context Menu Repair

## Overview

Repairs the Windows Explorer **"Open with Code"** entry so it shows up
**only when right-clicking folders**, not when right-clicking files or empty
folder backgrounds. After the registry is fixed, the script restarts
`explorer.exe` so the change takes effect immediately.

## Problem

Default and third-party installs of VS Code often add the "Open with Code"
entry in three places at once:

1. `HKCR\*\shell\VSCode` -- shows on every **file** right-click
2. `HKCR\Directory\shell\VSCode` -- shows on **folder** right-click (the one we want)
3. `HKCR\Directory\Background\shell\VSCode` -- shows on every empty area inside a folder

That clutters the menu. Users reported they only want the folder entry.

## Solution

A focused PowerShell script that:

- Reads target lists from `config.json` (`removeFromTargets`, `ensureOnTargets`)
- Removes the file + background entries via `reg.exe delete /f`
- Re-creates / repairs the folder entry with correct label, icon, and `%V` command argument
- Verifies each target is in the expected state (present / absent)
- Restarts `explorer.exe` so Explorer picks up the new menu without sign-out

It reuses the registry + path-resolution helpers from script 10
(`10-vscode-context-menu-fix/helpers/registry.ps1`) so logic stays in one
place.

## File Structure

```
scripts/52-vscode-folder-repair/
  config.json
  log-messages.json
  run.ps1
  helpers/
    repair.ps1

spec/52-vscode-folder-repair/
  readme.md

.resolved/52-vscode-folder-repair/
  resolved.json    (auto-created)
```

## config.json keys

| Key                       | Type     | Description                                                |
|---------------------------|----------|------------------------------------------------------------|
| `enabled`                 | bool     | Master switch                                              |
| `editions.*`              | object   | Stable / Insiders edition definitions                      |
| `editions.*.vscodePath`   | object   | `user` and `system` install paths                          |
| `editions.*.registryPaths`| object   | Three keys: `file`, `directory`, `background`              |
| `editions.*.contextMenuLabel` | string | Menu label                                                |
| `installationType`        | string   | `user` or `system` -- preferred install root               |
| `enabledEditions`         | string[] | Editions to process                                        |
| `removeFromTargets`       | string[] | Targets to delete (default `["file","background"]`)        |
| `ensureOnTargets`         | string[] | Targets to keep + repair (default `["directory"]`)         |
| `restartExplorer`         | bool     | Whether to restart `explorer.exe` at the end               |
| `restartExplorerWaitMs`   | int      | Pause between kill and start                               |

## Execution Flow

1. Load config + log messages, banner, init logging
2. `git pull`, disabled check, **assert admin**
3. For each edition in `enabledEditions`:
   - Resolve VS Code exe (uses cached `.resolved/` first, then config paths,
     then Chocolatey shim, then `Get-Command` / `where.exe`)
   - For each `removeFromTargets`: delete the registry key (and its `\command`)
   - For each `ensureOnTargets`: ensure key exists with label, icon, command
   - Verify final state matches expectation
4. Restart `explorer.exe` (skippable with `.\run.ps1 no-restart` or
   `restartExplorer=false` in config)
5. Save resolved state, save log file

## Commands

```powershell
.\run.ps1               # Full repair + explorer restart
.\run.ps1 no-restart    # Repair only, leave Explorer running
.\run.ps1 -Help         # Show help
```

## CODE RED Compliance

Every remove / ensure / verify failure path logs the **exact registry path**
and the failure reason (`reg.exe exit N`, exception message, etc.) per the
project-wide error-management rule.

## Prerequisites

- Windows 10 / 11
- PowerShell 5.1+
- Administrator privileges
- VS Code installed (script 01) so the executable can be resolved


---

<!-- spec-footer:v1 -->

## Author

<div align="center">

### [Md. Alim Ul Karim](https://www.google.com/search?q=alim+ul+karim)

**[Creator & Lead Architect](https://alimkarim.com)** | [Chief Software Engineer](https://www.google.com/search?q=alim+ul+karim), [Riseup Asia LLC](https://riseup-asia.com)

</div>

A system architect with **20+ years** of professional software engineering experience across enterprise, fintech, and distributed systems. His technology stack spans **.NET/C# (18+ years)**, **JavaScript (10+ years)**, **TypeScript (6+ years)**, and **Golang (4+ years)**.

Recognized as a **top 1% talent at Crossover** and one of the top software architects globally. He is also the **Chief Software Engineer of [Riseup Asia LLC](https://riseup-asia.com/)** and maintains an active presence on **[Stack Overflow](https://stackoverflow.com/users/513511/md-alim-ul-karim)** (2,452+ reputation, 961K+ reached, member since 2010) and **LinkedIn** (12,500+ followers).

| | |
|---|---|
| **Website** | [alimkarim.com](https://alimkarim.com/) · [my.alimkarim.com](https://my.alimkarim.com/) |
| **LinkedIn** | [linkedin.com/in/alimkarim](https://linkedin.com/in/alimkarim) |
| **Stack Overflow** | [stackoverflow.com/users/513511/md-alim-ul-karim](https://stackoverflow.com/users/513511/md-alim-ul-karim) |
| **Google** | [Alim Ul Karim](https://www.google.com/search?q=Alim+Ul+Karim) |
| **Role** | Chief Software Engineer, [Riseup Asia LLC](https://riseup-asia.com) |

### Riseup Asia LLC — Top Software Company in Wyoming, USA

[Riseup Asia LLC](https://riseup-asia.com) is a **top-leading software company headquartered in Wyoming, USA**, specializing in building **enterprise-grade frameworks**, **research-based AI models**, and **distributed systems architecture**. The company follows a **"think before doing"** engineering philosophy — every solution is researched, validated, and architected before implementation begins.

**Core expertise includes:**

- 🏗️ **Framework Development** — Designing and shipping production-grade frameworks used across enterprise and fintech platforms
- 🧠 **Research-Based AI** — Inventing and deploying AI models grounded in rigorous research methodologies
- 🔬 **Think Before Doing** — A disciplined engineering culture where architecture, planning, and validation precede every line of code
- 🌐 **Distributed Systems** — Building scalable, resilient systems for global-scale applications

| | |
|---|---|
| **Website** | [riseup-asia.com](https://riseup-asia.com) |
| **Facebook** | [riseupasia.talent](https://www.facebook.com/riseupasia.talent/) |
| **LinkedIn** | [Riseup Asia](https://www.linkedin.com/company/105304484/) |
| **YouTube** | [@riseup-asia](https://www.youtube.com/@riseup-asia) |

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](../../LICENSE) file for the full text.

```
Copyright (c) 2026 Alim Ul Karim
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../../LICENSE)

---

<div align="center">

*Part of the Dev Tools Setup Scripts toolkit — see the [spec writing guide](../00-spec-writing-guide/readme.md) for the full readme contract.*

</div>
