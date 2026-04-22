<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 42 — Install Ollama" width="128" height="128"/>

# Spec 42 — Install Ollama

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-42-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Script 42 -- Install Ollama

## Purpose
Downloads and installs [Ollama](https://ollama.com) for running local LLMs on Windows. Configures models directory, sets `OLLAMA_MODELS` environment variable, and optionally pulls starter models.

## Directory Structure
```
scripts/42-install-ollama/
  config.json           # Paths, download URL, default models list
  log-messages.json     # All log message templates
  run.ps1               # Entry point (param: Command, Path, -Help)
  helpers/
    ollama.ps1          # Install-Ollama, Configure-OllamaModels, Pull-OllamaModels, Uninstall-Ollama
```

## Install Flow
1. Check if `ollama` is already on PATH
2. Download `OllamaSetup.exe` with retry (3 attempts, exponential backoff via `Invoke-DownloadWithRetry`)
3. Run installer silently (`/VERYSILENT /NORESTART /SUPPRESSMSGBOXES`)
4. Refresh PATH so `ollama` is discoverable
5. Prompt user for models directory (default: `<dev-dir>\ollama-models`)
   - Skipped under orchestrator (`$env:SCRIPTS_ROOT_RUN = "1"`) -- uses default
6. Set `OLLAMA_MODELS` user environment variable
7. Offer to pull default models (Llama 3.2, Qwen 2.5 Coder, DeepSeek R1)
   - Auto-accepted under orchestrator

## Orchestrator Integration

When `$env:SCRIPTS_ROOT_RUN = "1"` (running under Script 12):

- Models directory prompt uses default (no `Read-Host`)
- Model pull confirmations auto-accept all models

## Commands

| Command     | Description                                      |
|-------------|--------------------------------------------------|
| `all`       | Install + configure models dir + pull models     |
| `install`   | Download and install Ollama only                  |
| `models`    | Configure models directory only                   |
| `pull`      | Pull default models (requires Ollama installed)   |
| `uninstall` | Remove Ollama, env vars, tracking                 |

## Install Keywords

| Keyword       | Scripts |
|---------------|---------|
| `ollama`      | 42      |
| `local-llm`   | 42      |
| `llm`         | 42      |
| `ai-tools`    | 42, 43  |
| `local-ai`    | 42, 43  |
| `ai-full`     | 5, 41, 42, 43 |

## Usage
```powershell
.\run.ps1 -I 42                    # Full install + models
.\run.ps1 install ollama           # Via keyword
.\run.ps1 -I 42 -- install        # Install only
.\run.ps1 -I 42 -- models         # Configure models dir only
.\run.ps1 -I 42 -- pull           # Pull models only
.\run.ps1 -I 42 -- uninstall      # Remove everything
```

## Dependencies

- Shared: `logging.ps1`, `resolved.ps1`, `git-pull.ps1`, `help.ps1`,
  `path-utils.ps1`, `dev-dir.ps1`, `installed.ps1`, `download-retry.ps1`,
  `disk-space.ps1`
- Requires: Administrator privileges, internet access

## Environment Variables Set
- `OLLAMA_MODELS` -- Path to models directory (user scope)

## Default Models
| Model | Size | Purpose |
|-------|------|---------|
| Llama 3.2 (3B) | ~2 GB | General |
| Qwen 2.5 Coder (7B) | ~4.7 GB | Coding |
| DeepSeek R1 (8B) | ~4.9 GB | Reasoning |

## Resolved State
Saved to `.resolved/42-install-ollama.json`:
- `ollamaVersion` -- Installed version string
- `modelsDir` -- Configured models directory
- `timestamp` -- ISO 8601 timestamp


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
