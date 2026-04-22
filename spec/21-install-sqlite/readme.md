<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 21 — Install Sqlite" width="128" height="128"/>

# Spec 21 — Install Sqlite

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-21-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Script 21 -- Install SQLite

## Purpose

Installs **SQLite CLI** and **DB Browser for SQLite** (GUI) with flexible
installation path options. Both are installed via Chocolatey.

---

## Usage

### From script folder (scripts/21-install-sqlite/)

```powershell
.\run.ps1          # Install SQLite CLI + DB Browser for SQLite
.\run.ps1 -Help    # Show usage
```

### From root dispatcher (project root)

```powershell
.\run.ps1 install sqlite       # Bare command
.\run.ps1 -Install sqlite      # Named parameter
```

### Via interactive database menu (script 30)

```powershell
.\run.ps1 install databases    # Select "4. SQLite" from the menu
```

---

## What Gets Installed

| # | Component | Choco Package | Purpose |
|---|-----------|---------------|---------|
| 1 | **SQLite CLI** | `sqlite` | Command-line interface for SQLite databases |
| 2 | **DB Browser for SQLite** | `sqlitebrowser` | GUI tool for browsing and editing SQLite databases |

Both components are toggled independently via `config.json`:
- `database.enabled` controls the SQLite CLI
- `database.browser.enabled` controls DB Browser for SQLite

---

## config.json

| Key | Type | Purpose |
|-----|------|---------|
| `devDir.mode` | string | Resolution mode (`json-or-prompt`) |
| `devDir.default` | string | Default dev directory path |
| `devDir.override` | string | Hard override (skips prompt) |
| `installMode.default` | string | Default install location (`devDir` / `custom` / `system`) |
| `database.enabled` | bool | Toggle SQLite CLI installation |
| `database.chocoPackage` | string | Chocolatey package for SQLite CLI (`sqlite`) |
| `database.verifyCommand` | string | Command to verify installation (`sqlite3`) |
| `database.versionFlag` | string | Flag to check version (`--version`) |
| `database.name` | string | Display name |
| `database.desc` | string | Short description |
| `database.type` | string | Category (`file-based`) |
| `database.browser.enabled` | bool | Toggle DB Browser for SQLite installation |
| `database.browser.name` | string | Friendly browser name (`DB Browser for SQLite`) |
| `database.browser.chocoPackage` | string | Chocolatey package (`sqlitebrowser`) |

---

## Install Path Options

1. **Dev directory** (default): `E:\dev-tool\sqlite`
2. **Custom path**: User-specified location
3. **System default**: Package manager default (e.g. `C:\Program Files`)

If the configured drive is unavailable or invalid, the shared dev-dir helper
falls back to a safe path such as `C:\dev-tool`.

---

## Execution Flow

```
run.ps1
  |
  +-- Assert admin privileges
  +-- Load config.json + log-messages.json
  +-- Resolve dev directory (with safe drive fallback)
  +-- Prompt for install location (dev dir / custom / system)
  |
  +-- SQLite CLI
  |     +-- Check if sqlite3 is already in PATH
  |     +-- If found: log version, save resolved state
  |     +-- If not found:
  |           +-- Install via Chocolatey (sqlite)
  |           +-- Refresh PATH
  |           +-- Verify sqlite3 is available
  |           +-- Save resolved state
  |
  +-- DB Browser for SQLite
  |     +-- Skip if browser.enabled is false
  |     +-- Install via Chocolatey (sqlitebrowser)
  |     +-- Log success or failure
  |
  +-- Show summary
```

---

## Helper Functions (helpers/sqlite.ps1)

| Function | Purpose |
|----------|---------|
| `Get-SqliteVersion` | Runs `sqlite3 --version` and returns the version string |
| `Save-SqliteResolvedState` | Writes version + timestamp to `.resolved/21-install-sqlite/` |
| `Install-SqliteBrowser` | Installs DB Browser for SQLite via Chocolatey if enabled |
| `Install-Sqlite` | Main orchestrator: installs CLI, verifies, then installs browser |

---

## Resolved State

On successful install, the script saves to `.resolved/21-install-sqlite/resolved.json`:

```json
{
  "version": "3.46.0 2024-05-23 ...",
  "resolvedAt": "2025-07-06T10:30:00.0000000+00:00",
  "resolvedBy": "USERNAME"
}
```

## Install Keywords

| Keyword |
|---------|
| `sqlite` |

```powershell
.\run.ps1 install sqlite
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
