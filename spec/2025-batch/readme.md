<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 2025 — Batch" width="128" height="128"/>

# Spec 2025 — Batch

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-2025-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# 2025 Batch -- New Commands, Tools, and Profiles

> Master index for the 2025 feature batch. Each numbered subdoc is a
> self-contained spec that another AI (or human) can implement in
> isolation. Implement in numeric order unless noted.

**Status**: spec only -- no code written yet.
**Target version**: v0.40.0 (minor bump per project rule).
**Created**: 2026-04-19 (Asia/Kuala_Lumpur, UTC+8).

---

## Decisions locked (from clarification round)

| Topic | Decision |
|-------|----------|
| Spec layout | One master spec (this file) + per-feature subdocs (`01-*.md` ... `12-*.md`) |
| Profile invocation | **Both** -- new keywords in `install-keywords.json` AND new `profile` subcommand |
| "OS dir" installs | Skip dev-dir prompt -- use Chocolatey default (`C:\ProgramData\chocolatey` shims, `C:\Program Files\<tool>`). No `--install-arguments` overrides. |
| ConEmu XML location | `settings/06 - conemu/ConEmu.xml` -- copied to `%APPDATA%\ConEmu\` after install. Mirrors notepad++ / obs / windows-terminal pattern. |
| `add-user` password | **Plain CLI args** (`add-user name pass [pin] [email]`). User accepted the security risk. Password is masked in console output but written to argv. |
| WhatsApp / OneNote | **Chocolatey desktop installers** -- no Microsoft Store, no winget Store source. `choco install whatsapp -y`, OneNote via Office or `choco install onenote -y` (fallback to download). |
| `git-safe-all` (`gsa`) | **Both modes** -- default = wildcard (`safe.directory = *`). `--scan <path>` flag = walk dir, add per-repo `safe.directory <full-path>` entries. |

---

## Subdoc index

| # | Subdoc | Script ID | Folder | Keywords |
|---|--------|-----------|--------|----------|
| 01 | `01-ubuntu-font.md` | 47 | `47-install-ubuntu-font` | `ubuntu-font`, `ubuntu.font` |
| 02 | `02-conemu.md` | 48 | `48-install-conemu` | `conemu`, `conemu+settings`, `conemu-settings` |
| 03 | `03-whatsapp.md` | 49 | `49-install-whatsapp` | `whatsapp`, `wa` |
| 04 | `04-os-clean.md` | n/a (subcommand) | `os/` dispatcher | `os clean` |
| 05 | `05-git-safe-all.md` | n/a (subcommand) | `git/` dispatcher | `git-safe-all`, `gsa` |
| 06 | `06-onenote.md` | 50 | `50-install-onenote` | `onenote` |
| 07 | `07-fix-long-path.md` | n/a (subcommand) | `os/` dispatcher | `fix-long-path`, `flp` |
| 08 | `08-add-user.md` | n/a (subcommand) | `os/` dispatcher | `os add-user` |
| 09 | `09-lightshot.md` | 51 | `51-install-lightshot` | `lightshot` |
| 10 | `10-hibernate-off.md` | n/a (subcommand) | `os/` dispatcher | `os hib-off` |
| 11 | `11-psreadline.md` | n/a | folded into Base profile | `psreadline` |
| 12 | `12-profiles.md` | n/a | new `profile/` dispatcher | `profile base`, `profile git-compact`, `profile advance`, `profile cpp-dx`, `profile small-dev` |

---

## New script registrations (scripts/registry.json)

```json
"47": "47-install-ubuntu-font",
"48": "48-install-conemu",
"49": "49-install-whatsapp",
"50": "50-install-onenote",
"51": "51-install-lightshot"
```

## New combo keywords (scripts/shared/install-keywords.json)

```json
"ubuntu-font":      [47],
"ubuntu.font":      [47],
"conemu":           [48],
"conemu+settings":  [48],
"conemu-settings":  [48],
"whatsapp":         [49],
"wa":               [49],
"onenote":          [50],
"lightshot":        [51],
"profile-base":     [14, 7, "vlc", "7zip.install", "winrar", 47, 33, 48, "googlechrome", 36],
"profile-git":      [7, 8],
"profile-advance":  ["profile-base", "profile-git", "wordweb-free", "beyondcompare", 36, 49, 1, 11],
"profile-cpp-dx":   ["vcredist-all", "directx", "directx-sdk"],
"profile-small-dev":["profile-advance", 6, 5, 3, 4]
```
*(IDs vs. string keys: existing infra is integer-only. Profile keywords need string-resolution support -- see `12-profiles.md`.)*

## New subcommand dispatchers

Two new top-level dispatchers under `scripts/`:

- `scripts/os/run.ps1` -- handles `os clean`, `os hib-off`, `os add-user`, `os flp`, `os fix-long-path`
- `scripts/git-tools/run.ps1` -- handles `gsa`, `git-safe-all`

Routed from `run.ps1` (root dispatcher) via new branches:
```powershell
if ($Command -eq "os")          { & "$PSScriptRoot\scripts\os\run.ps1" @Rest }
if ($Command -eq "git-safe-all" -or $Command -eq "gsa") { ... }
if ($Command -eq "profile")     { & "$PSScriptRoot\scripts\profile\run.ps1" @Rest }
```

## Implementation order (recommended)

1. **Spec review** -- this file + all 12 subdocs (current step). Sign-off required before any code.
2. **Group A -- Single-tool installers** (low risk, additive):
   - 01 ubuntu-font, 02 conemu, 03 whatsapp, 06 onenote, 09 lightshot
3. **Group B -- OS subcommands** (touches root dispatcher):
   - `os` dispatcher skeleton, then 04 clean, 07 flp, 08 add-user, 10 hib-off
4. **Group C -- Git tools**:
   - 05 git-safe-all
5. **Group D -- Profiles** (depends on A, B, C):
   - 12 profile dispatcher + 5 profile recipes
6. **Group E -- Polish**:
   - 11 psreadline (folded into Base, no separate script)
   - Default git config update (filter.lfs, safe.directory, url rewrite)
   - Spec update + memory update + version bump to v0.40.0

## Versioning

- Each Group merge bumps **patch** (v0.39.1, v0.39.2, ...).
- Final Group E merge bumps **minor** to **v0.40.0** with the full batch in changelog.
- Per user rule: code changes must bump at least minor version, but inside a single batch we use patches and bump minor at the close.

## Files this batch will create or modify

**Create:**
- `spec/2025-batch/readme.md` (this file) + `01-*.md` ... `12-*.md`
- `scripts/47-install-ubuntu-font/` (run.ps1, config.json, log-messages.json, helpers/)
- `scripts/48-install-conemu/` (run.ps1, config.json, log-messages.json, helpers/conemu.ps1, helpers/sync.ps1)
- `scripts/49-install-whatsapp/`
- `scripts/50-install-onenote/`
- `scripts/51-install-lightshot/`
- `scripts/os/run.ps1` + `scripts/os/helpers/{clean,hibernate,longpath,add-user}.ps1` + log-messages.json
- `scripts/git-tools/run.ps1` + `scripts/git-tools/helpers/safe-all.ps1` + log-messages.json
- `scripts/profile/run.ps1` + `scripts/profile/helpers/{base,git-compact,advance,cpp-dx,small-dev}.ps1` + config.json + log-messages.json
- `settings/06 - conemu/ConEmu.xml` (already copied)
- `settings/06 - conemu/readme.txt` (already created)
- `.lovable/memory/features/2025-batch.md`

**Modify:**
- `scripts/registry.json` (+5 entries)
- `scripts/shared/install-keywords.json` (+15 entries)
- `run.ps1` (root dispatcher: add `os`, `gsa`/`git-safe-all`, `profile` branches)
- `scripts/07-install-git/config.json` (add `[safe] directory = *`, `[filter "lfs"]`, `[url "ssh://git@gitlab.com/"]`)
- `.lovable/plan.md`, `changelog.md`, `scripts/version.json`

## Open questions (none -- all answered in clarification round)

If new questions surface during implementation of any subdoc, append them to that subdoc's "Open questions" section and ping the user.

---

See subdocs `01-*.md` through `12-*.md` for full implementation details.


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
