<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 43 — Install Llama Cpp" width="128" height="128"/>

# Spec 43 — Install Llama Cpp

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-43-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Script 43 -- Install llama.cpp

## Purpose
Downloads llama.cpp pre-built binaries (CUDA, AVX2 CPU, KoboldCPP), extracts them to the dev directory, adds binary folders to user PATH, and provides an **interactive model picker** for downloading from an 81-model catalog via aria2c accelerated downloads.

## Directory Structure
```
scripts/43-install-llama-cpp/
  config.json           # Executable variants, aria2c config, paths
  models-catalog.json   # 81-model catalog with rich metadata (separate file)
  log-messages.json     # All log message templates
  run.ps1               # Entry point (param: Command, Path, -Help)
  helpers/
    llama-cpp.ps1       # Install-LlamaCppExecutables, Uninstall-LlamaCpp
    model-picker.ps1    # Show-ModelCatalog, Read-RamFilter, Read-SizeFilter, Read-SpeedFilter, Read-CapabilityFilter, Read-ModelSelection, Install-SelectedModels, Invoke-ModelInstaller
```

## Install Flow

### Pre-flight Checks
1. **Hardware detection** -- `Get-HardwareProfile` detects CUDA GPU (nvidia-smi, nvcc, WMI) and AVX2 CPU support (WMI + heuristic). Incompatible executable variants are skipped with clear logging.
2. **URL freshness** -- HEAD-checks executable download URLs; blocks if stale
3. **Disk space** -- blocks if insufficient space for executables

### Executables
1. Each variant in `config.executables` has a `requires` field (`"cuda"`, `"avx2"`, or `""`)
2. Variants whose `requires` hardware is not detected are skipped
3. Compatible variants: download, extract, verify, add to PATH
4. ZIP integrity validation (magic bytes + expected size)

### Interactive Model Picker
1. **aria2c setup** -- auto-installs via `choco install aria2`; falls back to `Invoke-DownloadWithRetry`
2. **Models directory** -- user picks custom path or Enter for default (`<dev-dir>\llama-models`)
3. **RAM filter** -- optional filter by available system RAM:
   - Preset tiers: 4, 8, 16, 32, 64 GB or auto-detected system RAM
   - Direct numeric input supported; Enter to skip
4. **Size filter** -- optional filter by download size tier:
   - `[1] Tiny (<1 GB)`, `[2] Small (<3 GB)`, `[3] Medium (<6 GB)`, `[4] Large (<12 GB)`, `[5] XLarge (12+ GB)`
   - Enter to skip; models re-indexed after filtering
5. **Speed filter** -- optional filter by inference speed tier:
   - `[1] Instant (<1 GB)`, `[2] Fast (<3 GB)`, `[3] Moderate (<8 GB)`, `[4] Slow (8+ GB)`
   - Supports multi-select (e.g. "1,2"); Enter to skip; models re-indexed after filtering
6. **Capability filter** -- optional filter menu before catalog display:
   - `[1] Coding`, `[2] Reasoning`, `[3] Writing`, `[4] Chat`, `[5] Voice`, `[6] Multilingual`
   - Supports same selection syntax as model picker (single, range, comma-separated)
   - Enter to skip filter and show all models; OR logic (any matching cap shown)
   - Models re-indexed after filtering for clean numbered display
6. **Catalog display** -- numbered list with columns: #, Model, Params, Quant, Size, RAM, Capabilities
   - Starred (recommended) models shown first, color-coded by rating
7. **Selection input** -- supports:
   - Single: `3`
   - Range: `1-5`
   - Mixed: `1-3,7,12-15`
   - All: `all`
   - Quit: `q`
8. **Disk space check** -- warns if insufficient for selected models
9. **Download** -- each model via aria2c (16 connections), tracked in `.installed/model-<id>.json`
10. **Summary** -- downloaded/skipped/failed counts

## Model Catalog (`models-catalog.json`)

- **81 models** across coding, reasoning, writing, voice, and general categories
- No hardcoded paths -- models directory resolved at runtime
- Rich metadata per model: `displayName`, `family`, `parameters`, `quantization`, `fileSizeGB`, `ramRequiredGB`, `ramRecommendedGB`, capability flags, `rating`, `bestFor`, `notes`, `license`, `downloadUrl`, `sha256`
- SHA256 checksums for download integrity verification (empty = skip check, populated gradually)
- Includes latest models: Gemma 3 (1B/4B/12B), Llama 3.2 (1B/3B), SmolLM2, Phi-4 Mini/14B, Granite 3.1, Qwen 3/3.5, Claude distills, Devstral, EXAONE 4.0, Whisper variants

## Commands

| Command       | Description                                          |
|---------------|------------------------------------------------------|
| `all`         | Download executables + interactive model picker       |
| `executables` | Download and extract executables only                 |
| `models`      | Interactive model picker only                         |
| `uninstall`   | Remove binaries, model tracking, clean PATH           |

## Dependencies

- Shared: `logging.ps1`, `resolved.ps1`, `git-pull.ps1`, `help.ps1`,
  `path-utils.ps1`, `dev-dir.ps1`, `installed.ps1`, `download-retry.ps1`,
  `disk-space.ps1`, `url-freshness.ps1`, `aria2c-download.ps1`, `choco-utils.ps1`,
  `hardware-detect.ps1`
- Optional: aria2c (auto-installed via Chocolatey; falls back to Invoke-WebRequest)
- Requires: Administrator privileges, internet access


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
