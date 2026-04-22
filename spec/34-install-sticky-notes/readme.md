<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 34 — Install Sticky Notes" width="128" height="128"/>

# Spec 34 — Install Sticky Notes

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-34-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Install Simple Sticky Notes (Script 34)

## Overview

Script 34 installs **Simple Sticky Notes** via Chocolatey -- a lightweight
desktop sticky notes application for Windows. Optionally redirects the SSN
data folder to a custom location (e.g. `D:\notes`) via directory symlink.

---

## Usage

```powershell
.\run.ps1 install sticky-notes       # Install Simple Sticky Notes
.\run.ps1 install stickynotes        # Alias
.\run.ps1 install ssn                # Short alias
.\run.ps1 -I 34                      # By script ID
.\run.ps1 -I 34 -- -Help             # Show help
```

## Keywords

| Keyword | Script ID |
|---------|-----------|
| `sticky-notes` | 34 |
| `stickynotes` | 34 |
| `sticky` | 34 |
| `ssn` | 34 |

---

## Config (`config.json`)

| Field | Value |
|-------|-------|
| `chocoPackage` | `simple-sticky-notes` |
| `enabled` | `true` |
| `verifyCommand` | `SimpleSticky` |
| `dataFolder.enabled` | `true` |
| `dataFolder.path` | `D:\notes` |
| `dataFolder.createIfMissing` | `true` |

---

## Execution Flow

1. Check if Simple Sticky Notes is already installed (common paths + `Get-Command`)
2. If found, log and skip
3. If missing, install via `choco install simple-sticky-notes -y`
4. Verify EXE exists at expected path after install (CODE RED: exact path logged on failure)
5. Save install record to `.installed/sticky-notes.json`
6. Save resolved state to `.resolved/34-install-sticky-notes/resolved.json`
7. If `dataFolder.enabled`, redirect SSN data to custom path via symlink

---

## Custom Data Folder

When `dataFolder.enabled` is `true`, the script:

1. Creates the target folder (e.g. `D:\notes`) if missing and `createIfMissing` is true
2. If `%APPDATA%\Simple Sticky Notes` exists as a real folder, moves its contents to the target
3. Creates a directory symlink: `%APPDATA%\Simple Sticky Notes` → `D:\notes`
4. If the symlink already points to the correct target, skips silently

This ensures SSN reads/writes all data (notes database, settings) from the custom location.

---

## Verification Paths

- `$env:ProgramFiles\Simple Sticky Notes\SimpleSticky.exe`
- `${env:ProgramFiles(x86)}\Simple Sticky Notes\SimpleSticky.exe`

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Simple Sticky Notes (Choco) | User selected over Microsoft Sticky Notes (UWP) or Stickies |
| EXE verification post-install | CODE RED rule: exact path logged if not found |
| `Install-ChocoPackage` helper | Consistent with all other Choco-based scripts |
| Symlink for data folder | Non-destructive redirect; SSN unaware of relocation |
| `createIfMissing` flag | Safety switch to prevent accidental folder creation |

## Install Keywords

| Keyword |
|---------|
| `sticky-notes` |
| `stickynotes` |
| `sticky` |
| `ssn` |

```powershell
.\run.ps1 install sticky-notes
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
