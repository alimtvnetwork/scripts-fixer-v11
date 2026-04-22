<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 40 — Install Java" width="128" height="128"/>

# Spec 40 — Install Java

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-40-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Script 40 -- Install Java (OpenJDK)

## Purpose

Install Java (OpenJDK) via Chocolatey with version selection support.
Users can install the latest OpenJDK or a specific LTS version.
Configures JAVA_HOME environment variable automatically.

## Subcommands

| Command | Description |
|---------|-------------|
| `all` | Install Java + set JAVA_HOME + configure PATH (default) |
| `install` | Install Java only |
| `install <version>` | Install a specific OpenJDK version |
| `uninstall` | Uninstall all Java versions, remove JAVA_HOME, clean PATH, purge tracking |
| `-Help` | Show usage information |

## Parameters

| Parameter | Position | Description |
|-----------|----------|-------------|
| `-Path` | 1 (after command) | Custom dev directory path. Overrides `$env:DEV_DIR`. |

## Version Selection

| Version | Choco Package | Description |
|---------|---------------|-------------|
| `latest` | `openjdk` | Newest OpenJDK (default) |
| `17` | `openjdk17` | OpenJDK 17 LTS |
| `21` | `openjdk21` | OpenJDK 21 LTS |

### Usage Examples

```powershell
.\run.ps1 -I 40                    # Install latest OpenJDK
.\run.ps1 -I 40 -- install 21     # Install OpenJDK 21 LTS
.\run.ps1 -I 40 -- install 17     # Install OpenJDK 17 LTS
.\run.ps1 -I 40 -- uninstall      # Full uninstall + cleanup
.\run.ps1 install java             # Via keyword (latest)
.\run.ps1 install openjdk          # Via keyword (latest)
.\run.ps1 install jdk-21           # Via keyword (OpenJDK 21)
.\run.ps1 install jdk-17           # Via keyword (OpenJDK 17)
```

## Uninstall

The `uninstall` subcommand performs a full cleanup:

1. **Chocolatey uninstall** -- removes all OpenJDK packages
2. **JAVA_HOME** -- removes the environment variable from User scope
3. **PATH cleanup** -- removes `<devDir>\java\bin` from User PATH
4. **Dev directory** -- deletes `<devDir>\java` subfolder
5. **Tracking records** -- purges `.installed/java-*.json` and `.resolved/40-install-java/`

## config.json

| Key | Type | Purpose |
|-----|------|---------|
| `enabled` | bool | Master toggle |
| `chocoPackages` | object | Maps version keys to Chocolatey package names |
| `defaultVersion` | string | Version to install when none specified |
| `availableVersions` | array | Valid version keys |
| `alwaysUpgradeToLatest` | bool | Upgrade on every run |
| `devDirSubfolder` | string | Subfolder under dev dir |
| `env.setJavaHome` | bool | Whether to set JAVA_HOME env var |
| `path.updateUserPath` | bool | Add java/bin to PATH |

## Flow

1. Assert admin + Chocolatey
2. Log install target directory
3. Resolve requested version (default: latest)
4. Install/upgrade Java via Chocolatey
5. Set JAVA_HOME environment variable
6. Add `<devDir>\java\bin` to User PATH
7. Save resolved state (java -version)

## Install Keywords

| Keyword |
|---------|
| `java` |
| `openjdk` |
| `jdk` |
| `jre` |
| `jdk-17` |
| `jdk-21` |


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
