<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 33 — Install Notepadpp" width="128" height="128"/>

# Spec 33 — Install Notepadpp

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-33-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Script 33 -- Install Notepad++

## Purpose

Install Notepad++ text editor via Chocolatey and/or sync curated settings
from the bundled zip to the user's AppData directory. Supports three modes.

## Naming Convention

| Shortcut Label | Meaning | Keyword |
|----------------|---------|---------|
| **NPP + Settings** | Install Notepad++ and sync settings | `npp+settings`, `notepad++`, `npp` |
| **NPP Settings** | Sync settings only (no install) | `npp-settings` |
| **Install NPP** | Install only (no settings sync) | `install-npp` |

> **NPP** always means **Notepad++**.

## Usage

```powershell
.\run.ps1 install npp              # NPP + Settings (default)
.\run.ps1 install npp+settings     # NPP + Settings (explicit)
.\run.ps1 install npp-settings     # NPP Settings only
.\run.ps1 install install-npp      # Install NPP only
.\run.ps1 -I 33 -- export         # Export settings from machine to repo
.\run.ps1 -I 33                    # NPP + Settings (default mode)
.\run.ps1 -I 33 -- -Mode settings-only   # NPP Settings only
.\run.ps1 -I 33 -- -Mode install-only    # Install NPP only
```

## Settings Package

The settings are bundled as `scripts/33-install-notepadpp/settings/notepadpp-settings.zip`.

The zip is extracted to the user-specific roaming path:
- `%APPDATA%\Notepad++\` (resolves to `C:\Users\{user}\AppData\Roaming\Notepad++\`)

This is a **full replace** -- all files in the zip overwrite whatever exists
in the target directory. Contents include: config.xml, themes, shortcuts,
function lists, plugins config, user-defined languages.

## Modes

### install+settings (NPP + Settings)

1. Install Notepad++ via Chocolatey (if not already installed)
2. Verify installation
3. Extract settings zip to `%APPDATA%\Notepad++\`

### settings-only (NPP Settings)

1. Skip Notepad++ installation entirely
2. Extract settings zip to `%APPDATA%\Notepad++\`

### install-only (Install NPP)

1. Install Notepad++ via Chocolatey (if not already installed)
2. Verify installation
3. Skip settings sync

## Mode Resolution Order

1. `-Mode` parameter on `run.ps1` (highest priority)
2. `$env:NPP_MODE` environment variable (set by keyword resolver)
3. Default: `install+settings`

## Config (`config.json`)

| Key | Type | Purpose |
|-----|------|---------|
| `notepadpp.enabled` | bool | Toggle script |
| `notepadpp.chocoPackage` | string | Chocolatey package name |
| `notepadpp.syncSettings` | bool | Whether to copy settings after install |
| `notepadpp.defaultMode` | string | Default mode when not specified |

## Log Messages

Defined in `log-messages.json`. Key messages:
- `alreadyInstalled` -- shown when Notepad++ version matches tracked record
- `syncingSettings` / `settingsSynced` -- settings extraction progress
- `settingsSkipped` -- no settings files found in script folder

## Helpers

| File | Function | Purpose |
|------|----------|---------|
| `notepadpp.ps1` | `Install-NotepadPP` | Install via Chocolatey, verify, track (accepts `-Mode`) |
| `notepadpp.ps1` | `Sync-NotepadPPSettings` | Extract settings zip to AppData |
| `notepadpp.ps1` | `Export-NotepadPPSettings` | Export settings from AppData back to repo |

## Settings Export

The export command copies Notepad++ settings FROM the machine back INTO the repo:

```powershell
.\run.ps1 -I 33 -- export
```

**Source:** `%APPDATA%\Notepad++\`
**Target:** `settings/01 - notepad++/`

Safety rules:
- Config files exported: `.xml`, `.json`, `.ini`, `.txt`
- Files larger than 512 KB are skipped (likely cache)
- `readme.txt` is preserved in the target directory
- Subdirectories exported recursively (themes, userDefineLangs, etc.)
- Runtime folders skipped: `backup`, `session`, `plugins`

## Install Keywords

| Keyword | Mode |
|---------|------|
| `notepad++` | install+settings |
| `notepadpp` | install+settings |
| `notepad-plus` | install+settings |
| `npp` | install+settings |
| `npp+settings` | install+settings |
| `npp-settings` | settings-only |
| `install-npp` | install-only |

```powershell
.\run.ps1 install notepad++
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
