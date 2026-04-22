<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 41 — Install Python Libs" width="128" height="128"/>

# Spec 41 — Install Python Libs

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-41-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Script 41 -- Install Python Libraries

## Purpose

Install common Python/ML libraries via `pip` into the configured
`PYTHONUSERBASE` directory. Packages are organized into groups that can
be installed individually or all at once.

## Subcommands

| Command | Description |
|---------|-------------|
| `all` | Install all configured libraries (default) |
| `group <name>` | Install a specific library group |
| `add <pkg ...>` | Install specific packages by name |
| `list` | List available groups and their packages |
| `installed` | Show currently installed pip packages |
| `uninstall` | Uninstall all tracked libraries |
| `uninstall <pkg>` | Uninstall specific packages |
| `-Help` | Show usage information |

## Library Groups

| Group | Label | Packages |
|-------|-------|----------|
| `ml` | Machine Learning | numpy, scipy, scikit-learn, torch, tensorflow, keras |
| `data` | Data & Analytics | pandas, polars |
| `viz` | Visualization | matplotlib, seaborn, plotly |
| `web` | Web Frameworks | django, flask, fastapi, uvicorn |
| `scraping` | Scraping & HTTP | requests, beautifulsoup4 |
| `cv` | Computer Vision | opencv-python |
| `db` | Database | sqlalchemy |
| `jupyter` | Jupyter Notebook | jupyterlab, notebook, ipykernel, ipywidgets |

## Parameters

| Parameter | Position | Description |
|-----------|----------|-------------|
| `-Path` | N/A | Not used directly; relies on `PYTHONUSERBASE` set by script 05 |

## config.json

| Key | Type | Purpose |
|-----|------|---------|
| `enabled` | bool | Master toggle |
| `requiresPython` | bool | Asserts Python is installed before proceeding |
| `installToUserSite` | bool | Use `--user` flag with pip (installs to PYTHONUSERBASE) |
| `groups` | object | Named groups of packages |
| `allPackages` | array | Full list of all packages for `all` command |

## Flow

1. Assert Python and pip are available
2. Check `PYTHONUSERBASE` -- if set, install with `--user` flag
3. Install requested packages (all, group, or custom)
4. Save resolved state with installed package list
5. Save installed record

## Install Keywords

**Single-script keywords** (script 41 only):

| Keyword | Description |
|---------|-------------|
| `python-libs` | Install all pip libraries |
| `pip-libs` | Install all pip libraries |
| `ml-libs` | ML/Data libraries |
| `ml-full` | ML libraries |
| `python-packages` | Install all pip libraries |
| `jupyter+libs` | Jupyter group only (mode: `group jupyter`) |

**Combo keywords** (installs Python 05 + libraries 41):

| Keyword | Scripts | Description |
|---------|---------|-------------|
| `pylibs` | 05, 41 | Python + all libraries in one go |
| `python+libs` | 05, 41 | Python + all libraries |
| `ml-dev` | 05, 41 | Python + all libraries |
| `python+jupyter` | 05, 41 | Python + all libraries |
| `pip+jupyter+libs` | 05, 41 | Python + all libraries |
| `data-science` | 05, 41 | Python + data/viz libs (mode: `group data`) |
| `datascience` | 05, 41 | Python + data/viz libs (mode: `group data`) |
| `ai-dev` | 05, 41 | Python + ML libs (mode: `group ml`) |
| `aidev` | 05, 41 | Python + ML libs (mode: `group ml`) |
| `deep-learning` | 05, 41 | Python + ML libs (mode: `group ml`) |

## Usage Examples

```powershell
# Via root dispatcher
.\run.ps1 install python-libs       # Install all libraries
.\run.ps1 install python+libs       # Install Python + all libraries
.\run.ps1 install jupyter+libs      # Install Jupyter group only
.\run.ps1 install data-science      # Python + data/viz group
.\run.ps1 install ai-dev            # Python + ML group
.\run.ps1 install python+jupyter    # Python + all libraries

# Via script directly
.\run.ps1 -I 41                     # Install all libraries
.\run.ps1 -I 41 -- group ml         # Install ML group only
.\run.ps1 -I 41 -- group jupyter    # Install Jupyter group
.\run.ps1 -I 41 -- group viz        # Install visualization only
.\run.ps1 -I 41 -- add jupyterlab streamlit  # Install custom packages
.\run.ps1 -I 41 -- list             # Show available groups
.\run.ps1 -I 41 -- installed        # Show pip packages
.\run.ps1 -I 41 -- uninstall        # Remove all tracked libraries
.\run.ps1 -I 41 -- uninstall numpy pandas  # Remove specific packages
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
