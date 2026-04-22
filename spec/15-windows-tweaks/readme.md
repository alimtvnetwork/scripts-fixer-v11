<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 15 — Windows Tweaks" width="128" height="128"/>

# Spec 15 — Windows Tweaks

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-15-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Windows Tweaks

## Overview

A PowerShell script that launches the **Chris Titus Windows Utility**
(`christitus.com/win`) for system tweaks, debloating, and Windows
configuration. This is a standalone utility kept outside the "Install All
Dev Tools" orchestrator (script 12).

---

## File Structure

```
scripts/15-windows-tweaks/
├── config.json              # URL, confirmation toggle
├── log-messages.json        # Display strings
├── run.ps1                  # Thin orchestrator
├── helpers/
│   └── tweaks.ps1           # Invoke-WindowsTweaks function
└── logs/                    # Auto-created (gitignored)

.resolved/15-windows-tweaks/
└── resolved.json            # Execution timestamp
```

## Usage

```powershell
.\run.ps1              # Launch the utility (with confirmation prompt)
.\run.ps1 -Help        # Show usage
```

Or via root dispatcher:

```powershell
.\run.ps1 -I 15        # Run via root dispatcher
.\run.ps1 -t           # Shortcut for -I 15
```

## config.json Schema

| Key | Type | Description |
|-----|------|-------------|
| `enabled` | bool | Master enable/disable for the entire script |
| `tweaks.url` | string | URL for the Chris Titus utility script |
| `tweaks.confirmBeforeRun` | bool | Prompt user for confirmation before downloading and running |

## Execution Flow

1. If `-Help`: display usage and exit
2. Load shared helpers (logging, resolved, help)
3. Load script helper (tweaks.ps1)
4. Git pull (unless `$env:SCRIPTS_ROOT_RUN`)
5. Assert admin privileges
6. If `confirmBeforeRun`: prompt Y/N
7. Download script via `Invoke-RestMethod`
8. Execute via `Invoke-Expression`
9. Save resolved timestamp to `.resolved/`

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Outside orchestrator (script 12) | System tweaks are not dev tool installs; user preference |
| Confirmation prompt by default | Running remote scripts should require explicit consent |
| Configurable URL | Allows pointing to forks or specific versions |

## Install Keywords

| Keyword |
|---------|
| `tweaks` |
| `windows-tweaks` |
| `windowstweaks` |

```powershell
.\run.ps1 install tweaks
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
