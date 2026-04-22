<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec — Dev Tools Setup" width="128" height="128"/>

# Spec — Dev Tools Setup

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Spec](https://img.shields.io/badge/Spec-Toolkit-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Dev Environment Setup Scripts (01-10)

## Overview

A suite of PowerShell scripts that set up a complete Windows development
environment from scratch. Each script handles one concern and can run
standalone or be orchestrated by script 04.

All dev tools are installed into a configurable **dev directory** (default: `E:\dev`)
with structured subdirectories per tool.

---

## Script Inventory

| Script | Folder | Purpose | Requires Admin |
|--------|--------|---------|----------------|
| 01 | `01-vscode-context-menu-fix` | Restore "Open with Code" context menu entries | Yes |
| 02 | `02-vscode-settings-sync` | Import VS Code settings, keybindings, extensions | No |
| 03 | `03-install-package-managers` | Install/update Chocolatey + Winget | Yes |
| 04 | `04-install-all-dev-tools` | Orchestrator: runs 03, 05-10 in sequence | Yes |
| 05 | `05-install-golang` | Install Go via Choco, configure GOPATH + go env | Yes |
| 06 | `06-install-nodejs` | Install Node.js via Choco, configure npm prefix | Yes |
| 07 | `07-install-python` | Install Python via Choco, configure pip | Yes |
| 08 | `08-install-pnpm` | Install + configure pnpm (global store in dev dir) | No |
| 09 | `09-install-git` | Install Git + Git LFS + GitHub CLI, configure settings | Yes |
| 10 | `10-install-github-desktop` | Install GitHub Desktop via Choco | Yes |

---

## Shared Dev Directory Structure

```
E:\dev\                                # Configurable root (default E:\dev)
├── go\                                # GOPATH
│   ├── bin\                           # Go binaries (added to PATH)
│   ├── pkg\mod\                       # GOMODCACHE
│   └── cache\build\                   # GOCACHE
├── nodejs\                            # Node.js custom install prefix
│   └── node_modules\                  # Global modules
├── python\                            # Python user site / virtualenvs
│   └── Scripts\                       # pip scripts (added to PATH)
└── pnpm\                              # pnpm global store
    └── store\                         # Content-addressable store
```

---

## Shared Helpers (scripts/shared/)

| File | Functions | Purpose |
|------|-----------|---------|
| `logging.ps1` | `Write-Log`, `Write-Banner` | Colorful logging with level badges |
| `resolved.ps1` | `Save-ResolvedData`, `Import-JsonConfig` | JSON config loading + state persistence |
| `git-pull.ps1` | `Invoke-GitPull` | Auto-pull latest scripts on run |
| `help.ps1` | `Show-ScriptHelp` | Standardized --help output |
| `path-utils.ps1` | `Add-ToUserPath`, `Add-ToMachinePath`, `Test-InPath` | Safe PATH manipulation with dedup |
| `choco-utils.ps1` | `Assert-Choco`, `Install-ChocoPackage`, `Upgrade-ChocoPackage` | Chocolatey wrappers with logging |
| `dev-dir.ps1` | `Resolve-DevDir`, `Initialize-DevDir` | Dev directory resolution + creation |
| `json-utils.ps1` | JSON merge utilities | Deep-merge for settings sync |
| `cleanup.ps1` | Cleanup utilities | Post-run cleanup |

---

## Script 03: install-package-managers

### Purpose
Install and/or update Chocolatey and Winget package managers.

### Subcommands
```powershell
.\run.ps1 choco              # Install/update Chocolatey only
.\run.ps1 winget             # Install/verify Winget only
.\run.ps1 all                # Install both (default)
.\run.ps1 -Help              # Show available commands
```

---

## Script 04: install-golang

### Purpose
Install Go via Chocolatey, configure GOPATH, GOMODCACHE, GOCACHE, GOPROXY,
GOPRIVATE, and update PATH.

### Subcommands
```powershell
.\run.ps1                    # Install + configure (default "all")
.\run.ps1 install            # Install/upgrade Go only
.\run.ps1 configure          # Configure GOPATH/env only
.\run.ps1 -Help              # Show usage
```

---

## Script 05: install-nodejs

### Purpose
Install Node.js (LTS) via Chocolatey, configure npm global prefix inside dev dir.

### Subcommands
```powershell
.\run.ps1                    # Install + configure (default)
.\run.ps1 install            # Install/upgrade only
.\run.ps1 configure          # Configure npm prefix only
.\run.ps1 -Help              # Show usage
```

---

## Script 06: install-python

### Purpose
Install Python via Chocolatey, configure pip user site inside dev dir.

### Subcommands
```powershell
.\run.ps1                    # Install + configure (default)
.\run.ps1 install            # Install/upgrade only
.\run.ps1 configure          # Configure pip only
.\run.ps1 -Help              # Show usage
```

---

## Script 07: install-pnpm

### Purpose
Install pnpm globally and configure the global store inside dev dir.

### Subcommands
```powershell
.\run.ps1                    # Install + configure (default)
.\run.ps1 install            # Install only
.\run.ps1 configure          # Configure store only
.\run.ps1 -Help              # Show usage
```

---

## Script 09: install-git

### Purpose
Install Git, Git LFS, and GitHub CLI via Chocolatey. Configure global git
settings including user identity, default branch, credential manager,
line endings, editor, and push behavior.

### Subcommands
```powershell
.\run.ps1                    # Install all + configure (default)
.\run.ps1 install            # Install Git + LFS + gh only
.\run.ps1 configure          # Configure settings + PATH only
.\run.ps1 -Help              # Show usage
```

---

## Script 10: install-github-desktop

### Purpose
Install GitHub Desktop via Chocolatey.

### Subcommands
```powershell
.\run.ps1                    # Install (default)
.\run.ps1 -Help              # Show usage
```

---

## Script 04: install-all-dev-tools

### Purpose
Orchestrator that runs scripts 03, 05-10 in sequence. Resolves the dev directory
once, passes it to all child scripts via `$env:DEV_DIR`.

### Sequence
`03 (Package Managers) > 09 (Git + LFS + gh) > 04 (Go) > 05 (Node.js) > 06 (Python) > 07 (pnpm) > 10 (GitHub Desktop)`

### Subcommands
```powershell
.\run.ps1                    # Run all (default)
.\run.ps1 -Skip "05,07"     # Skip Node.js and pnpm
.\run.ps1 -Only "03,04"     # Run only package managers + Go
.\run.ps1 -Help              # Show available commands
```

---

## --help Convention

Every script supports `-Help` which prints:
- Script name and version
- One-line description
- Available subcommands with descriptions
- Example usage

---

## Conventions (all scripts follow)

| Convention | Detail |
|------------|--------|
| Shared helpers | Dot-source from `scripts/shared/` |
| Script helpers | `helpers/` subfolder per script |
| Config files | `config.json` (read-only at runtime) |
| Log messages | `log-messages.json` for all display strings |
| Runtime state | `.resolved/<script-folder>/resolved.json` |
| Logging | Shared `Write-Log -Level` with status badges |
| Banner | `Write-Banner -Title -Version` |
| Help | `Show-ScriptHelp -LogMessages` |
| Admin check | Inline check with `$logMessages.messages.notAdmin` |
| PATH safety | Dedup before adding, user PATH preferred |
| Dev dir | All tools install into `$env:DEV_DIR` subfolders |
| No hardcoded paths | Everything in config.json with env var expansion |


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
