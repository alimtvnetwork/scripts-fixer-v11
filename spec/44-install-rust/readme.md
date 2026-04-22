<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 44 — Install Rust" width="128" height="128"/>

# Spec 44 — Install Rust

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-44-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Script 44 -- Install Rust

## Purpose

Install the Rust toolchain via rustup (rustup-init.exe), configure components
(clippy, rustfmt, rust-analyzer), optionally add WASM target and cargo packages,
and ensure `~/.cargo/bin` is in the user PATH.

## Subcommands

| Command | Description |
|---------|-------------|
| `all` | Install Rust + components + PATH setup (default) |
| `install` | Install/upgrade Rust toolchain only |
| `components` | Install configured components only |
| `uninstall` | Uninstall via `rustup self uninstall` |
| `-Help` | Show usage information |

## config.json

| Key | Type | Purpose |
|-----|------|---------|
| `enabled` | bool | Master toggle |
| `installMethod` | string | Always `rustup` |
| `rustupUrl` | string | URL for rustup-init.exe |
| `defaultToolchain` | string | Toolchain channel (stable/nightly/beta) |
| `alwaysUpgradeToLatest` | bool | Run `rustup update` on every run |
| `components.clippy` | bool | Install clippy linter |
| `components.rustfmt` | bool | Install code formatter |
| `components.rust-analyzer` | bool | Install LSP server |
| `targets.addWasm` | bool | Add wasm32-unknown-unknown target |
| `cargoPackages.enabled` | bool | Install cargo packages |
| `cargoPackages.packages` | array | List of cargo packages to install |
| `path.updateUserPath` | bool | Add cargo/bin to PATH |

## Flow

1. Assert admin
2. Check if `rustc` exists -- skip or upgrade
3. If missing: download rustup-init.exe, run with `-y --default-toolchain stable`
4. Install components: clippy, rustfmt, rust-analyzer
5. Optionally add WASM target
6. Optionally install cargo packages
7. Ensure `~/.cargo/bin` in PATH
8. Save resolved state (rustc, cargo, rustup versions)

## Install Keywords

| Keyword |
|---------|
| `rust` |
| `rustup` |
| `cargo` |
| `rustlang` |

**Group shortcuts**:

| Keyword | Scripts |
|---------|---------|
| `systems-dev` | 9, 44 |
| `full-stack` | 1, 2, 3, 4, 5, 7, 8, 9, 11, 16, 39, 40, 44 |

## Dependencies

- Shared: `logging.ps1`, `resolved.ps1`, `git-pull.ps1`, `help.ps1`,
  `path-utils.ps1`, `installed.ps1`, `download-retry.ps1`
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
