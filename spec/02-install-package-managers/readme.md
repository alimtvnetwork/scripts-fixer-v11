<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 02 — Install Package Managers" width="128" height="128"/>

# Spec 02 — Install Package Managers

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-02-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Install Chocolatey

## Overview

A PowerShell script that installs and/or updates **Chocolatey**
package manager on Windows. This is a prerequisite for scripts 03-09.

Winget was previously part of this script but has been extracted to
**script 14** (`14-install-winget`) as a standalone utility.

---

## File Structure

```
scripts/02-install-package-managers/
├── config.json              # Enable/disable, install URL
├── log-messages.json        # Display strings and banners
├── run.ps1                  # Thin orchestrator
├── helpers/
│   └── choco.ps1            # Install-Chocolatey function
└── logs/                    # Auto-created (gitignored)

.resolved/02-install-package-managers/
└── resolved.json            # Installed version + timestamp
```

## Usage

```powershell
.\run.ps1              # Install/update Chocolatey
.\run.ps1 -Help        # Show usage
```

## config.json Schema

| Key | Type | Description |
|-----|------|-------------|
| `enabled` | bool | Master enable/disable for the entire script |
| `chocolatey.enabled` | bool | Whether to install/check Chocolatey |
| `chocolatey.installUrl` | string | URL for Chocolatey install script |
| `chocolatey.upgradeOnRun` | bool | Upgrade Chocolatey itself on every run |

## Execution Flow

1. If `-Help`: display usage and exit
2. Load shared helpers (logging, choco-utils, resolved, help)
3. Load script helper (choco.ps1)
4. Git pull (unless `$env:SCRIPTS_ROOT_RUN`)
5. Assert admin privileges
6. Call `Install-Chocolatey` with config
7. Save resolved version to `.resolved/`
8. Display summary

## Prerequisites

- **Windows 10/11**
- **PowerShell 5.1+**
- **Administrator privileges**
- **Internet access** (for downloads)

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Winget extracted to script 14 | Winget is optional and OS-bundled; keeps this script focused on Chocolatey |
| Assert-Choco from shared helper | Same logic reused by scripts 03-09 |
| Versions saved to .resolved/ | Other scripts can check prerequisite versions |
## Install Keywords

| Keyword |
|---------|
| `choco` |
| `chocolatey` |
| `package-managers` |
| `packagemanagers` |

**Group shortcuts** (installs multiple scripts):

| Keyword | Scripts |
|---------|---------|
| `full-stack` | 1, 2, 3, 4, 5, 7, 8, 9, 11, 16 |
| `fullstack` | 1, 2, 3, 4, 5, 7, 8, 9, 11, 16 |
| `essentials` | 1, 2, 3, 7, 11 |

```powershell
.\run.ps1 install choco
.\run.ps1 install full-stack
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
