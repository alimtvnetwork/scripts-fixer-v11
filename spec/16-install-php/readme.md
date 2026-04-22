<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 16 — Install Php" width="128" height="128"/>

# Spec 16 — Install Php

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-16-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Script 16 -- Install PHP (+ phpMyAdmin)

## Purpose

Install PHP and/or phpMyAdmin via Chocolatey. Supports three modes.

## Naming Convention

| Shortcut Label | Meaning | Keyword |
|----------------|---------|---------|
| **PHP + phpMyAdmin** | Install PHP and phpMyAdmin | `php`, `php+phpmyadmin` |
| **PHP only** | Install PHP without phpMyAdmin | `php-only` |
| **phpMyAdmin only** | Install phpMyAdmin without PHP | `phpmyadmin`, `phpmyadmin-only` |

## File Structure

```
scripts/16-install-php/
├── config.json              # Package names, modes, verify command
├── log-messages.json        # Display strings
├── run.ps1                  # Entry point (accepts -Mode param)
├── helpers/
│   └── php.ps1              # Install-Php + Install-PhpMyAdmin functions
└── logs/                    # Auto-created (gitignored)
```

## Usage

```powershell
.\run.ps1 install php                # PHP + phpMyAdmin (default)
.\run.ps1 install php+phpmyadmin     # PHP + phpMyAdmin (explicit)
.\run.ps1 install php-only           # PHP only
.\run.ps1 install phpmyadmin         # phpMyAdmin only
.\run.ps1 -I 16                      # PHP + phpMyAdmin (default mode)
.\run.ps1 -I 16 -- -Mode php-only   # PHP only
.\run.ps1 -I 16 -- -Mode phpmyadmin-only  # phpMyAdmin only
```

## Modes

### php+phpmyadmin (default)

1. Install PHP via Chocolatey (if not already installed)
2. Verify PHP installation
3. Install phpMyAdmin via Chocolatey (if not already installed)

### php-only

1. Install PHP via Chocolatey (if not already installed)
2. Verify PHP installation
3. Skip phpMyAdmin

### phpmyadmin-only

1. Skip PHP installation
2. Install phpMyAdmin via Chocolatey (if not already installed)

## Mode Resolution Order

1. `-Mode` parameter on `run.ps1` (highest priority)
2. `$env:PHP_MODE` environment variable (set by keyword resolver)
3. Default: `php+phpmyadmin`

## Config (`config.json`)

| Key | Type | Purpose |
|-----|------|---------|
| `php.enabled` | bool | Toggle PHP install |
| `php.chocoPackage` | string | Chocolatey package name (`php`) |
| `php.verifyCommand` | string | Command to verify PHP (`php`) |
| `phpmyadmin.enabled` | bool | Toggle phpMyAdmin install |
| `phpmyadmin.chocoPackage` | string | Chocolatey package name (`phpmyadmin`) |
| `defaultMode` | string | Default mode when not specified |

## Execution Flow

1. If `-Help`: display usage and exit
2. Load shared + script helpers
3. Git pull (unless `$env:SCRIPTS_ROOT_RUN`)
4. Assert admin privileges
5. Announce mode
6. Install PHP (unless phpmyadmin-only)
7. Install phpMyAdmin (unless php-only)
8. Save resolved data and install records

## Log Messages

Defined in `log-messages.json`. Key messages:
- `pmaChecking` / `pmaFound` -- phpMyAdmin detection
- `pmaInstalling` / `pmaInstallSuccess` -- install progress
- `pmaInstallFailed` -- failure with CODE RED path logging
- `pmaSkipped` -- shown in php-only mode

## Helpers

| File | Function | Purpose |
|------|----------|---------|
| `php.ps1` | `Install-Php` | Install PHP via Chocolatey, verify, track |
| `php.ps1` | `Install-PhpMyAdmin` | Install phpMyAdmin via Chocolatey, track |

## Install Keywords

| Keyword | Mode |
|---------|------|
| `php` | php+phpmyadmin |
| `phpmyadmin` | phpmyadmin-only |
| `php+phpmyadmin` | php+phpmyadmin |
| `php-only` | php-only |
| `phpmyadmin-only` | phpmyadmin-only |

**Group shortcuts** (installs multiple scripts):

| Keyword | Scripts |
|---------|---------|
| `full-stack` | 1, 2, 3, 4, 5, 7, 8, 9, 11, 16 |
| `fullstack` | 1, 2, 3, 4, 5, 7, 8, 9, 11, 16 |
| `backend` | 5, 6, 16, 20 |

```powershell
.\run.ps1 install php
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
