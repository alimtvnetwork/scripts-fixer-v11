<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 39 — Install Dotnet" width="128" height="128"/>

# Spec 39 — Install Dotnet

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-39-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Script 39 -- Install .NET SDK

## Purpose

Install .NET SDK via Chocolatey with version selection support.
Users can install the latest SDK or a specific LTS/STS version.

## Subcommands

| Command | Description |
|---------|-------------|
| `all` | Install .NET SDK + configure PATH (default) |
| `install` | Install .NET SDK only |
| `install <version>` | Install a specific .NET SDK version |
| `uninstall` | Uninstall all .NET SDKs, clean PATH, purge tracking |
| `-Help` | Show usage information |

## Parameters

| Parameter | Position | Description |
|-----------|----------|-------------|
| `-Path` | 1 (after command) | Custom dev directory path. Overrides `$env:DEV_DIR`. |

## Version Selection

| Version | Choco Package | Description |
|---------|---------------|-------------|
| `latest` | `dotnet-sdk` | Newest stable SDK (default) |
| `6` | `dotnet-6.0-sdk` | .NET 6 LTS |
| `8` | `dotnet-8.0-sdk` | .NET 8 LTS |
| `9` | `dotnet-9.0-sdk` | .NET 9 STS |

### Usage Examples

```powershell
.\run.ps1 -I 39                    # Install latest .NET SDK
.\run.ps1 -I 39 -- install 8      # Install .NET 8 LTS
.\run.ps1 -I 39 -- install 6      # Install .NET 6 LTS
.\run.ps1 -I 39 -- install 9      # Install .NET 9 STS
.\run.ps1 -I 39 -- uninstall      # Full uninstall + cleanup
.\run.ps1 install dotnet           # Via keyword (latest)
.\run.ps1 install dotnet-8         # Via keyword (.NET 8)
.\run.ps1 install csharp           # Via keyword (latest)
```

## Uninstall

The `uninstall` subcommand performs a full cleanup:

1. **Chocolatey uninstall** -- removes all .NET SDK packages
2. **PATH cleanup** -- removes dev directory from User PATH
3. **Dev directory** -- deletes `<devDir>\dotnet` subfolder
4. **Tracking records** -- purges `.installed/dotnet-*.json` and `.resolved/39-install-dotnet/`

## config.json

| Key | Type | Purpose |
|-----|------|---------|
| `enabled` | bool | Master toggle |
| `chocoPackages` | object | Maps version keys to Chocolatey package names |
| `defaultVersion` | string | Version to install when none specified |
| `availableVersions` | array | Valid version keys |
| `alwaysUpgradeToLatest` | bool | Upgrade on every run |
| `devDirSubfolder` | string | Subfolder under dev dir |
| `path.updateUserPath` | bool | Add dotnet dir to PATH |

## Flow

1. Assert admin + Chocolatey
2. Log install target directory
3. Resolve requested version (default: latest)
4. Install/upgrade .NET SDK via Chocolatey
5. Add dev dir to User PATH
6. Save resolved state (dotnet --version, --list-sdks)

## Install Keywords

| Keyword |
|---------|
| `dotnet` |
| `.net` |
| `dotnet-sdk` |
| `csharp` |
| `c#` |
| `dotnet-6` |
| `dotnet-8` |
| `dotnet-9` |


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
