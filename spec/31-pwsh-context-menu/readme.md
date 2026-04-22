<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 31 — Pwsh Context Menu" width="128" height="128"/>

# Spec 31 — Pwsh Context Menu

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-31-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: PowerShell Context Menu

## Overview

A PowerShell utility that adds **"Open PowerShell Here"** entries to the Windows
Explorer right-click context menu -- both normal and elevated (Run as Admin).

---

## Problem

Windows does not always provide a convenient "Open PowerShell Here" option in
the context menu, especially for the modern `pwsh` (PowerShell 7+). Users need:

1. Right-click a **folder** -> "Open PowerShell Here"
2. Right-click the **background** of a folder -> "Open PowerShell Here"
3. Same as above but with **admin elevation** (UAC prompt)

## Solution

A structured PowerShell script that:

- Auto-detects the latest `pwsh.exe` (PowerShell 7+) with fallback to legacy `powershell.exe`
- Creates registry entries for both **normal** and **admin** modes
- Uses `HasLUAShield` registry value for proper UAC elevation prompts
- Reads all configuration from external JSON files

---

## File Structure

```
scripts/31-pwsh-context-menu/
  config.json                  # Paths, modes, registry keys (read-only at runtime)
  log-messages.json            # All display strings
  run.ps1                      # Main script entry point
  helpers/
    pwsh-menu.ps1              # Detection + registry helpers

spec/31-pwsh-context-menu/
  readme.md                    # This specification

.resolved/31-pwsh-context-menu/
  resolved.json                # Detected exe path, timestamp (auto-created)
```

## config.json Schema

| Key                          | Type     | Description                                    |
|------------------------------|----------|------------------------------------------------|
| `enabled`                    | bool     | Master enable/disable switch                   |
| `modes.normal`               | object   | Normal (non-elevated) context menu config      |
| `modes.admin`                | object   | Admin (elevated via UAC) context menu config   |
| `modes.*.contextMenuLabel`   | string   | Label shown in the right-click menu            |
| `modes.*.registryPaths.directory`  | string | Registry key for folder context menu     |
| `modes.*.registryPaths.background` | string | Registry key for folder background menu  |
| `modes.*.commandArgs.*`      | string   | Command template (`{exe}` replaced at runtime) |
| `modes.admin.runas`          | bool     | If true, sets HasLUAShield for UAC prompt      |
| `enabledModes`               | string[] | Which modes to process: `["normal", "admin"]`  |
| `pwshPaths.programFiles`     | string   | Scan path pattern for Program Files install    |
| `pwshPaths.winget`           | string   | WindowsApps path (winget installs)             |
| `pwshPaths.legacy`           | string   | Legacy powershell.exe fallback                 |
| `verifyCommand`              | string   | Command to check PATH (`pwsh`)                 |
| `versionFlag`                | string   | Flag to get version (`--version`)              |
| `fallbackToLegacy`           | bool     | Whether to fall back to powershell.exe          |

## Execution Flow

1. Load config and log messages
2. Display banner, run git pull
3. Assert Administrator privileges
4. **Detect PowerShell executable** (Resolve-PwshPath):
   a. Check `pwsh` on PATH
   b. Scan `C:\Program Files\PowerShell\{7,6,...}\pwsh.exe` (highest first)
   c. Check winget WindowsApps path
   d. Fallback to legacy `powershell.exe` (if enabled)
5. For each enabled mode (normal, admin):
   a. Register context menu for **directories**
   b. Register context menu for **folder backgrounds**
   c. For admin mode: set `HasLUAShield` for UAC elevation
   d. Verify all registry entries
6. Save resolved state to `.resolved/`
7. Display summary

## Admin Elevation (HasLUAShield)

The admin mode entry uses the `HasLUAShield` registry value, which tells
Windows Explorer to show the UAC shield icon and trigger an elevation prompt
when the menu item is clicked. The command itself runs normally -- Windows
handles the elevation via `ShellExecute` with the `runas` verb internally.

## Prerequisites

- **Windows 10/11**
- **PowerShell 5.1+** (to run the script itself)
- **Administrator privileges**
- **pwsh installed** (script 17) or legacy powershell.exe as fallback

## Install Keywords

| Keyword |
|---------|
| `pwsh-menu` |
| `pwsh-context-menu` |
| `ps-context-menu` |

```powershell
.\run.ps1 install pwsh-menu
```


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
