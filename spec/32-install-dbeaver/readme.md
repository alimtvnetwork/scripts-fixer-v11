<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 32 — Install Dbeaver" width="128" height="128"/>

# Spec 32 — Install Dbeaver

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-32-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Install DBeaver Community

## Overview

Installs DBeaver Community Edition, a universal database visualization and
management tool that supports MySQL, PostgreSQL, SQLite, MongoDB, Redis,
and many other databases. Optionally syncs connection profiles and settings
from a local settings folder.

## What It Does

1. Checks if DBeaver is already installed (PATH + common install locations)
2. Installs DBeaver Community via Chocolatey (`choco install dbeaver`)
3. Refreshes PATH and verifies the install
4. Syncs settings from `settings/04 - dbeaver/` to `%APPDATA%\DBeaverData\workspace6\General\.dbeaver\`
5. Saves resolved state to `.resolved/32-install-dbeaver/resolved.json`

## Modes

| Mode | Description |
|------|-------------|
| `install+settings` | Install DBeaver + sync settings (default) |
| `settings-only` | Sync settings only (no admin required) |
| `install-only` | Install DBeaver only (skip settings sync) |

## Configuration

| Key | Purpose |
|-----|---------|
| `database.enabled` | Enable/disable the install |
| `database.chocoPackage` | Chocolatey package name (`dbeaver`) |
| `database.verifyCommand` | CLI command to verify install (`dbeaver-cli`) |
| `database.syncSettings` | Enable/disable settings sync |
| `database.defaultMode` | Default mode (`install+settings`) |

## Settings Sync

The settings sync feature copies configuration files from the repo's
`settings/04 - dbeaver/` folder to DBeaver's data directory:

```
%APPDATA%\DBeaverData\workspace6\General\.dbeaver\
```

Supported files:
- `data-sources.json` -- Connection profiles
- `credentials-config.json` -- Encrypted credential store
- Any subdirectories (drivers, templates, etc.)

## Settings Export

The export command copies settings FROM the machine back INTO the repo for
backup and version control:

```powershell
.\run.ps1 -I 32 -- export
```

**Source:** `%APPDATA%\DBeaverData\workspace6\General\.dbeaver\`
**Target:** `settings/04 - dbeaver/`

Safety rules:
- Only `.json` config files are exported (no binaries)
- Files larger than 512 KB are skipped (likely cache, not config)
- `readme.txt` is preserved in the target directory
- Subdirectories (drivers, templates) are exported recursively

## Usage

```powershell
.\run.ps1 -I 32                        # Install DBeaver + sync settings
.\run.ps1 install dbeaver              # Install via keyword (default mode)
.\run.ps1 install dbeaver-settings     # Sync settings only
.\run.ps1 install install-dbeaver      # Install only (no settings)
.\run.ps1 -I 32 -- export             # Export settings from machine to repo
.\run.ps1 -I 32 -- -Help              # Show help
.\run.ps1 -I 32 -- -Mode settings-only # Explicit mode
```

## Notes

- DBeaver Community is free and open-source (Apache 2.0 license)
- The `dbeaver-cli` command may not be in PATH on all systems; the installer
  also checks `Program Files\DBeaver\` as a fallback
- Settings-only mode does not require admin privileges
- Pairs well with database installs (SQLite, MySQL, PostgreSQL, etc.)

## Install Keywords

| Keyword | Mode |
|---------|------|
| `dbeaver` | install+settings |
| `db-viewer` | install+settings |
| `dbviewer` | install+settings |
| `dbeaver+settings` | install+settings |
| `dbeaver-settings` | settings-only |
| `install-dbeaver` | install-only |

**Group shortcuts** (installs multiple scripts):

| Keyword | Scripts |
|---------|---------|
| `data-dev` | 20, 24, 28, 32 |
| `datadev` | 20, 24, 28, 32 |

```powershell
.\run.ps1 install dbeaver
.\run.ps1 install data-dev
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
