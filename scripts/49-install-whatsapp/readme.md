<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Script 49 — Install Whatsapp" width="128" height="128"/>

# Script 49 — Install Whatsapp

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-49-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.74.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

## Overview

Implementation folder for **Script 49 — Install Whatsapp**. Installs WhatsApp Desktop via Chocolatey, with an automatic fallback (added in v0.73.0) to the official Microsoft-published `WhatsAppSetup.exe` installer when the Chocolatey package fails or its install path cannot be verified. The full design contract lives in the spec.

## Quick start

```powershell
# From repo root
.\run.ps1 -I 49 install

# Force-test the fallback path (point choco at a bogus package name)
# Edit config.json -> whatsapp.chocoPackage = "whatsapp-does-not-exist"
.\run.ps1 -I 49 install

# Uninstall (now sweeps registry + shortcuts after choco -- v0.74.0+)
.\run.ps1 -I 49 uninstall
```

## Fallback behaviour (v0.73.0+)

If `choco install whatsapp` returns failure, **or** completes but `WhatsApp.exe` is not found in any expected install root, the script downloads `https://web.whatsapp.com/desktop/windows/release/x64/WhatsAppSetup.exe` and runs it silently with `/S`. Configurable under `config.json -> whatsapp.fallback`. Installs recorded via fallback are tracked with `Method = "official-installer"` so you can tell them apart from Chocolatey installs in `.installed/`.

## Uninstall cleanup (v0.74.0+)

After `choco uninstall whatsapp` runs, `Invoke-WaPostUninstallCleanup` sweeps leftover state:

- **Registry**: HKCU/HKLM `Software\WhatsApp`, `Software\Classes\WhatsApp`, `Uninstall\WhatsApp`, autostart `Run\WhatsApp`.
- **Shortcuts**: Start Menu (per-user + all-users, `.lnk` and folder), Desktop (per-user + public), Taskbar pin, Start Menu pin.
- **AppData (opt-in)**: `%LOCALAPPDATA%\WhatsApp` is **kept by default** (chat cache lives here). Set `config.whatsapp.uninstallCleanup.purgeAppData = true` to nuke it.

Each target is logged individually (removed / missing-clean / failed) plus a one-line summary. Disable the whole sweep by setting `config.whatsapp.uninstallCleanup.enabled = false`.

## Layout

| File | Purpose |
|------|---------|
| `run.ps1` | Entry point dispatched by the root `run.ps1`. |
| `config.json` | External config (paths, toggles, edition list). |
| `log-messages.json` | All user-facing messages (kept out of code). |
| `helpers/` | Internal PowerShell helper modules. |

## See also

- [Full spec](../../spec/49-install-whatsapp/readme.md)
- [Spec writing guide](../../spec/00-spec-writing-guide/readme.md)
- [Changelog](../../changelog.md)


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

*Part of the Dev Tools Setup Scripts toolkit — see the [spec writing guide](../../spec/00-spec-writing-guide/readme.md) for the full readme contract.*

</div>
