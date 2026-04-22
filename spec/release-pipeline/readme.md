<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec — Release Pipeline" width="128" height="128"/>

# Spec — Release Pipeline

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

# Release Pipeline

## Overview

`release.ps1` packages project assets into a versioned ZIP archive under the `.release/` directory. The version is read from `.gitmap/release/latest.json`.

## Output

```
.release/dev-tools-setup-v<version>.zip
```

## Contents of the ZIP

| Item               | Type      | Description                              |
|--------------------|-----------|------------------------------------------|
| `scripts/`         | Directory | All numbered script folders + shared/    |
| `run.ps1`          | File      | Root dispatcher                          |
| `bump-version.ps1` | File      | Version bump utility                     |
| `readme.md`        | File      | Project readme                           |
| `LICENSE`          | File      | License file                             |
| `changelog.md`     | File      | Changelog                                |

## Parameters

| Parameter  | Type   | Description                                      |
|------------|--------|--------------------------------------------------|
| `-Force`   | Switch | Overwrite an existing ZIP for the same version    |
| `-DryRun`  | Switch | Preview what would be packaged without creating   |

## Usage

```powershell
# Build release ZIP for current version
.\release.ps1

# Preview contents without creating ZIP
.\release.ps1 -DryRun

# Overwrite existing ZIP
.\release.ps1 -Force
```

## Workflow

1. Reads version from `.gitmap/release/latest.json`
2. Creates `.release/` directory if missing
3. Stages `scripts/`, `run.ps1`, `bump-version.ps1`, `readme.md`, `LICENSE`, `changelog.md` into a temp directory
4. Compresses staged files into `dev-tools-setup-v<version>.zip`
5. Reports file count and ZIP size
6. Cleans up the staging directory

## Notes

- Missing source files are skipped with a warning (not a failure)
- Existing ZIP for the same version is skipped unless `-Force` is used
- The `.release/` folder should be added to `.gitignore`

---

## CI: Registry Summary Drift Detection (since v0.40.3)

`.github/workflows/release.yml` runs an additional **drift check** step on every tag push, after the version-alignment check and before the ZIP build:

1. Hashes the committed `spec/script-registry-summary.md`.
2. Runs `node scripts/_internal/generate-registry-summary.cjs` (overwrites the file in the runner workspace only).
3. Hashes the regenerated file and compares to the original.
4. If hashes differ, the release **fails** with a `::error` annotation, prints the full `git diff` of what changed, and refuses to publish the GitHub Release.

This guarantees `spec/script-registry-summary.md` can never silently drift from `scripts/registry.json` + per-script `config.json`. To recover from a failed drift check:

```powershell
node scripts/_internal/generate-registry-summary.cjs
git add spec/script-registry-summary.md
git commit -m "Refresh script-registry-summary"
# Then re-tag.
```

`bump-version.ps1` runs the same generator locally on every version bump, so a normal release flow never trips this gate.


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
