<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec — Audit" width="128" height="128"/>

# Spec — Audit

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

# Spec: Audit Mode

## Overview

A dedicated audit script that scans the entire project for stale IDs,
mismatched folder names, missing cross-references, and renumbering
inconsistencies. Designed to run after any renumbering or restructuring.

## Checks Performed

| # | Check | Description |
|---|-------|-------------|
| 1 | **Registry vs folders** | Every ID in `scripts/registry.json` must map to an existing folder under `scripts/`. Every numbered folder must appear in the registry. |
| 2 | **Orchestrator config vs registry** | Every ID in `scripts/12-install-all-dev-tools/config.json` `sequence` and `scripts` must exist in the registry. |
| 3 | **Orchestrator groups vs scripts** | Every ID referenced in `config.json` `groups[].ids` must exist in the `scripts` block. |
| 4 | **Spec folder coverage** | Every numbered script folder must have a matching `spec/<folder>/readme.md`. |
| 5 | **Config + log-messages existence** | Every script folder must contain `config.json` and `log-messages.json`. |
| 6 | **Stale ID references in specs** | Scan `spec/**/*.md` for patterns like `Script NN` or `scripts/NN-` that reference non-existent IDs. |
| 7 | **Stale ID references in suggestions** | Scan `suggestions/**/*.md` for the same stale-reference patterns. |
| 8 | **Stale ID references in PowerShell** | Scan `scripts/**/*.ps1` for hardcoded folder references like `01-install-vscode` and verify they match registry entries. |
| 9 | **Keyword modes vs config validModes** | Every mode value in `install-keywords.json` `modes` must exist in the target script's `config.json` `validModes` array. |
| 10 | **Verify database symlinks** | Scans `dev-tool\databases\` for broken junctions, missing links, and real directories. Supports `-Fix` and `-DryRun`. |
| 11 | **Uninstall coverage** | Every script (except 02, 12, audit, databases) must have: an `Uninstall-*` function in helpers, an `uninstall` command in `run.ps1`, and uninstall help in `log-messages.json`. |
| 12 | **Export coverage** | Every settings-capable script (32, 33, 36, 37) must have: an `Export-*` function in helpers, an `export` command in `run.ps1`, and export-related messages in `log-messages.json`. |

## Usage

```powershell
.\run.ps1 -I 13                   # Run full audit
.\run.ps1 -I 13 -- -DryRun        # Preview symlink repairs without changes
.\run.ps1 -I 13 -- -Fix           # Run audit and auto-fix broken symlinks
.\run.ps1 -I 13 -- -Report        # Run audit and save JSON health report
.\run.ps1 -I 13 -- -Help          # Show help
.\run.ps1 -h                      # Shortcut: audit + report
.\run.ps1 health                  # Keyword shortcut: audit (ID 13)
```

## Install Keywords

| Keyword |
|---------|
| `audit` |
| `health` |
| `health-check` |
| `healthcheck` |

## Output

- Each check prints PASS or FAIL with details
- Exit summary shows total pass/fail counts
- Non-zero exit code if any check fails

## Health Report (`-Report`)

When `-Report` is passed, a JSON file is saved to `logs/health-check_<timestamp>.json` containing:

| Field | Description |
|-------|-------------|
| `timestamp` | ISO 8601 timestamp of the run |
| `version` | Project version from `scripts/version.json` |
| `totalChecks` | Number of checks executed |
| `passed` | Count of passing checks |
| `failed` | Count of failing checks |
| `status` | `"healthy"` or `"unhealthy"` |
| `checks` | Array of per-check results with `passed` and `issues` |


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
