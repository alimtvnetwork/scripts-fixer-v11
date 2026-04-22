<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 05 — Install Python" width="128" height="128"/>

# Spec 05 — Install Python

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-05-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Script 05 -- Install Python

## Purpose

Install Python via Chocolatey and configure `PYTHONUSERBASE` so that
`pip install --user` targets the shared dev directory.

## Subcommands

| Command | Description |
|---------|-------------|
| `all` | Install Python + configure pip (default) |
| `install` | Install/upgrade Python only |
| `configure` | Configure pip site and PATH only |
| `uninstall` | Uninstall Python, remove env vars, clean dev dir, purge tracking |
| `-Help` | Show usage information |

## Parameters

| Parameter | Position | Description |
|-----------|----------|-------------|
| `-Path` | 1 (after command) | Custom dev directory path. Overrides smart drive detection and `$env:DEV_DIR`. All pip site configuration uses this path. |

### Usage with -Path

```powershell
.\run.ps1 all F:\dev-tool           # Install + configure pip to F:\dev-tool\python
.\run.ps1 install D:\projects  # Install Python, dev dir set to D:\projects
.\run.ps1 -Path E:\dev-tool         # Same as: .\run.ps1 all E:\dev
.\run.ps1 configure G:\tools   # Configure pip site to G:\tools\python
```

When `-Path` is provided, the script skips smart drive detection entirely
and uses the given path as the dev directory. The pip user site will be
set to `<Path>\python` (the `devDirSubfolder` from config.json).

## Uninstall

The `uninstall` subcommand performs a full cleanup:

1. **Chocolatey uninstall** -- removes the Python package and its dependencies
2. **Environment variable** -- removes `PYTHONUSERBASE` from User scope
3. **PATH cleanup** -- removes the `Scripts\` directory from User PATH
4. **Dev directory** -- deletes the `<devDir>\python` subfolder and all its contents
5. **Tracking records** -- purges `.installed/python.json` and `.resolved/05-install-python/`

```powershell
.\run.ps1 uninstall            # Full uninstall with smart dev dir detection
.\run.ps1 uninstall E:\dev-tool     # Uninstall, clean E:\dev-tool\python specifically
```

## config.json

| Key | Type | Purpose |
|-----|------|---------|
| `enabled` | bool | Master toggle |
| `chocoPackageName` | string | Chocolatey package (`python3`) |
| `alwaysUpgradeToLatest` | bool | Upgrade on every run |
| `devDirSubfolder` | string | Subfolder under dev dir |
| `installer.version` | string | Python version to install (e.g. `3.13.5`) |
| `installer.downloadUrl` | string | Official python.org installer URL |
| `installer.fileName` | string | Installer exe filename |
| `installer.installDirSubfolder` | string | Subfolder under `<devDir>/python/` (e.g. `Python313`) |
| `installer.allUsers` | bool | Install for all users |
| `installer.includePip` | bool | Include pip in installation |
| `pip.setUserSite` | bool | Whether to set PYTHONUSERBASE |
| `path.updateUserPath` | bool | Add Scripts dir to PATH |
| `path.ensurePipInPath` | bool | Ensure pip is reachable |

## Smart Drive Detection

When no `-Path` is provided and `$env:DEV_DIR` is not set, the script
automatically selects the best drive for the Python install directory:

1. **E: drive** (preferred)
2. **D: drive** (secondary)
3. **Any other non-system fixed drive** with the most free space (minimum 10 GB)
4. **Prompt the user** if no drive qualifies

The install directory becomes `<bestDrive>:\dev-tool\python\Python313`.
Users can always override with `-Path`.

## Flow

1. Assert admin + Chocolatey
2. Install/upgrade Python via Chocolatey
3. Set `PYTHONUSERBASE` env var to dev dir subfolder
4. Add `Scripts\` to User PATH
5. Save resolved state

## Install Keywords

| Keyword | Scripts | Description |
|---------|---------|-------------|
| `python` | 05 | Install Python + pip |
| `pip` | 05 | Install Python + pip |
| `python-pip` | 05 | Install Python + pip |
| `pythonpip` | 05 | Install Python + pip |
| `python+pip` | 05 | Install Python + pip |
| `pylibs` | 05, 41 | Python + all pip libraries (numpy, pandas, jupyter, etc.) |

**Group shortcuts** (installs multiple scripts):

| Keyword | Scripts | Description |
|---------|---------|-------------|
| `full-stack` | 01-09, 11, 16, 39, 40 | Everything for full-stack dev |
| `fullstack` | 01-09, 11, 16, 39, 40 | Everything for full-stack dev |
| `backend` | 05, 06, 16, 20, 39, 40 | Python + Go + PHP + PG + .NET + Java |
| `python+libs` | 05, 41 | Python + all libraries |
| `ml-dev` | 05, 41 | Python + all libraries |
| `data-science` | 05, 41 | Python + data/viz libs |
| `ai-dev` | 05, 41 | Python + ML libs |

```powershell
.\run.ps1 install python
.\run.ps1 install pylibs             # Python + all pip libraries in one go
.\run.ps1 install full-stack
.\run.ps1 install backend
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
