<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec — Choco Update" width="128" height="128"/>

# Spec — Choco Update

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Spec](https://img.shields.io/badge/Spec-Toolkit-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Choco Update Command

## Overview

The `.\run.ps1 update` command checks for outdated Chocolatey packages,
displays a formatted table, and upgrades them with user confirmation.
Supports selective updates, check-only mode, auto-confirm, and exclude lists.

---

## Usage

```powershell
.\run.ps1 update                              # Show outdated, confirm, upgrade all
.\run.ps1 update nodejs,git                   # Upgrade specific packages only
.\run.ps1 update --check                      # List outdated packages (no upgrade)
.\run.ps1 update -y                           # Upgrade all, skip confirmation
.\run.ps1 update nodejs -y                    # Upgrade nodejs, skip confirmation
.\run.ps1 update --exclude=chocolatey,dotnet  # Upgrade all except listed
.\run.ps1 upgrade                             # Alias for update
.\run.ps1 choco-update                        # Alias for update
```

---

## Execution Flow

### Default (no arguments)

1. Verify Chocolatey is installed (`choco.exe` in PATH)
2. Run `choco outdated --limit-output` to find packages with available updates
3. Display formatted table: Package | Current | Available
4. Show count of outdated packages
5. Prompt: "Upgrade N package(s)? [Y/n]"
6. If confirmed, run `choco upgrade all -y`
7. Report success or failure

### Selective Update (`update <packages>`)

1. Parse comma-separated package names from remaining arguments
2. Confirm with user (unless `-y`)
3. Upgrade each package individually via `choco upgrade <name> -y`
4. Report per-package success/failure and summary

### Check-Only (`update --check`)

1. Run `choco outdated --limit-output`
2. Display outdated table
3. Exit without upgrading

### Auto-Confirm (`update -y`)

1. Same as default flow but skips the [Y/n] prompt
2. Also works with selective: `update nodejs -y`

### Exclude (`update --exclude=pkg1,pkg2`)

1. Run `choco outdated --limit-output`
2. Filter out excluded packages from the outdated list
3. Upgrade remaining packages individually
4. Report per-package results

---

## Accepted Commands

| Command | Behaviour |
|---------|-----------|
| `update` | Outdated check + confirm + upgrade all |
| `update nodejs,git` | Upgrade specific packages only |
| `update --check` | List outdated, no upgrade |
| `update -y` | Upgrade all, skip confirmation |
| `update --exclude=pkg1,pkg2` | Upgrade all except listed |
| `upgrade` | Alias for `update` |
| `choco-update` | Alias for `update` |

---

## Argument Parsing

Arguments after `update` are parsed from positional remaining args:

| Pattern | Effect |
|---------|--------|
| `--check` or `-check` | Sets check-only mode |
| `-y` or `--yes` | Sets auto-confirm mode |
| `--exclude=pkg1,pkg2` | Sets exclusion list (comma-separated after `=`) |
| Anything else | Treated as package name(s), split on commas |

The root `-Y` switch is also honored for auto-confirm.

---

## Implementation

| File | Purpose |
|------|---------|
| `scripts/shared/choco-update.ps1` | `Get-ChocoOutdated`, `Show-OutdatedTable`, `Invoke-ChocoUpdate` |
| `run.ps1` | Argument parsing, delegates to `Invoke-ChocoUpdate` |

### Functions

| Function | Purpose |
|----------|---------|
| `Get-ChocoOutdated` | Runs `choco outdated --limit-output`, returns structured array |
| `Show-OutdatedTable` | Formats and displays the outdated packages table |
| `Invoke-ChocoUpdate` | Main entry point with all update modes |

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| `choco outdated` instead of `choco list` | Shows only actionable updates, not all packages |
| `--limit-output` flag | Machine-parseable pipe-delimited output |
| Individual upgrades for exclude mode | `choco upgrade all` has no native `--except` support |
| Auto-confirm via both `-y` arg and `-Y` switch | Consistent with existing Defaults mode pattern |
| Check-only exits cleanly | No side effects, safe for CI/scheduled checks |


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
