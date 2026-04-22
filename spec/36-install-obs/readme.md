<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 36 — Install Obs" width="128" height="128"/>

# Spec 36 — Install Obs

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-36-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Script 36 -- Install OBS Studio

## Purpose

Install OBS Studio via Chocolatey and/or sync curated scene collections
and profiles from the bundled settings zip. Supports three modes.

## Naming Convention

| Shortcut Label | Meaning | Keyword |
|----------------|---------|---------|
| **OBS + Settings** | Install OBS and sync settings | `obs+settings`, `obs` |
| **OBS Settings** | Sync settings only (no install) | `obs-settings` |
| **Install OBS** | Install only (no settings sync) | `install-obs` |

## Usage

```powershell
.\run.ps1 install obs              # OBS + Settings (default)
.\run.ps1 install obs+settings     # OBS + Settings (explicit)
.\run.ps1 install obs-settings     # OBS Settings only
.\run.ps1 install install-obs      # Install OBS only
.\run.ps1 -I 36 -- export         # Export settings from machine to repo
.\run.ps1 -I 36                    # OBS + Settings (default mode)
.\run.ps1 -I 36 -- -Mode settings-only   # OBS Settings only
.\run.ps1 -I 36 -- -Mode install-only    # Install OBS only
```

## Settings Package

The settings zip lives in the shared settings folder:
- `settings/02 - obs-settings/*.zip`

The first `.zip` found in that directory is used.

### Sync Process

1. Extract the zip to a **temp directory** (`%TEMP%\obs-settings-extract-<timestamp>`)
2. Copy all `.json` files (scene collections) to `%APPDATA%\obs-studio\basic\scenes\`
3. Copy all subdirectories (profiles) to `%APPDATA%\obs-studio\basic\profiles\`
4. Clean up the temp directory

OBS Studio automatically discovers scene collections and profiles from these
directories on startup -- no CLI import command is needed.

### Important: Settings always sync

When the install check finds OBS is already installed (via `.installed/obs.json`),
the install step is skipped but **settings sync still runs** in `install+settings`
mode. This is intentional -- the user may want to restore corrupted or changed settings.

### Zip Contents (example)

```
01__Alim_2023_v10__Gaming__Audio_Best.json     # Scene collection -> basic\scenes\
02__Alim_2024_v10__Single_Recorder.json        # Scene collection -> basic\scenes\
03_Interview.json                              # Scene collection -> basic\scenes\
...
Alim_Workstation_11_Pro_Profile_2024/          # Profile folder   -> basic\profiles\
  basic.ini
```

## Modes

### install+settings (OBS + Settings)

1. Install OBS Studio via Chocolatey (if not already installed)
2. Verify installation
3. Extract zip to temp, copy scenes + profiles to AppData

### settings-only (OBS Settings)

1. Skip OBS installation entirely
2. Extract zip to temp, copy scenes + profiles to AppData

### install-only (Install OBS)

1. Install OBS Studio via Chocolatey (if not already installed)
2. Verify installation
3. Skip settings sync

## Mode Resolution Order

1. `-Mode` parameter on `run.ps1` (highest priority)
2. `$env:OBS_MODE` environment variable (set by keyword resolver)
3. Default: `install+settings`

## Config (`config.json`)

| Key | Type | Purpose |
|-----|------|---------|
| `obs.enabled` | bool | Toggle script |
| `obs.chocoPackage` | string | Chocolatey package name (`obs-studio`) |
| `obs.syncSettings` | bool | Whether to copy settings after install |
| `obs.defaultMode` | string | Default mode when not specified |

## Verification Paths

- `$env:ProgramFiles\obs-studio\bin\64bit\obs64.exe`
- `${env:ProgramFiles(x86)}\obs-studio\bin\64bit\obs64.exe`

## Log Messages

Defined in `log-messages.json`. Key messages:
- `alreadyInstalled` -- shown when OBS version matches tracked record
- `syncingSettings` / `settingsSynced` -- settings extraction progress
- `settingsSkipped` -- no settings files found in settings source

## Helpers

| File | Function | Purpose |
|------|----------|---------|
| `obs.ps1` | `Install-OBS` | Install via Chocolatey, verify, track (accepts `-Mode`) |
| `obs.ps1` | `Sync-OBSSettings` | Extract zip to temp, copy scenes + profiles to AppData |
| `obs.ps1` | `Export-OBSSettings` | Export scenes + profiles from AppData back to repo |

## Settings Export

The export command copies OBS settings FROM the machine back INTO the repo:

```powershell
.\run.ps1 -I 36 -- export
```

**Source:** `%APPDATA%\obs-studio\basic\scenes\` and `%APPDATA%\obs-studio\basic\profiles\`
**Target:** `settings/02 - obs-settings/`

Safety rules:
- Only `.json` scene collections are exported (no binaries)
- Files larger than 512 KB are skipped
- Profile folders are exported recursively

## Install Keywords

| Keyword | Mode |
|---------|------|
| `obs` | install+settings |
| `obs-studio` | install+settings |
| `obs+settings` | install+settings |
| `obs-settings` | settings-only |
| `install-obs` | install-only |

```powershell
.\run.ps1 install obs
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
