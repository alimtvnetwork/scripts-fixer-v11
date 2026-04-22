<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec — Doctor" width="128" height="128"/>

# Spec — Doctor

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

# Spec: Doctor Command

## Purpose

Quick health-check that verifies the project setup itself. Lighter than
full audit -- runs in < 2 seconds for quick sanity checks.

## Usage

```powershell
.\run.ps1 doctor
```

## Checks Performed

| # | Check | Pass | Fail | Warn |
|---|-------|------|------|------|
| 1 | Scripts directory exists | Found | Not found | -- |
| 2 | version.json is valid | Parsed, version present | Parse error or empty | -- |
| 3 | registry.json is valid | Parsed, count shown | Parse error | -- |
| 4 | Registry folders exist | All folders present | Missing folders listed | -- |
| 5 | .logs/ directory exists | Found + file count | -- | Created on first run |
| 6 | .installed/ directory exists | Found + tool count | -- | No tools tracked yet |
| 7 | Chocolatey is reachable | Found + version | Not in PATH | -- |
| 8 | Running as Administrator | Yes | -- | Some scripts require admin |
| 9 | Shared helpers present | All 9 found | Missing listed | -- |
| 10 | install-keywords.json valid | Parsed + keyword count | Parse error | -- |

## Output Format

```
  Project Doctor
  ==============

    [PASS] Scripts directory exists -- D:\project\scripts
    [PASS] version.json is valid -- v0.17.1
    [PASS] registry.json is valid -- 41 scripts registered
    [PASS] Registry folders exist -- All 41 folders present
    [PASS] .logs/ directory exists -- 5 log file(s)
    [PASS] .installed/ directory exists -- 8 tool(s) tracked
    [PASS] Chocolatey is reachable -- v2.6.0
    [WARN] Running as Administrator -- Some scripts require admin rights
    [PASS] Shared helpers present -- 9 helpers found
    [PASS] install-keywords.json is valid -- 154 keywords mapped

  Summary: 9 passed, 1 warning(s)

  Project looks good with minor warnings.
```

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| No admin required | Doctor itself just reads files |
| No Chocolatey operations | Fast execution, no network |
| Color-coded output | Instant visual scan |
| Summary line | Quick pass/fail count |


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
