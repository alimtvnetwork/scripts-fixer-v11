<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 38 — Install Flutter" width="128" height="128"/>

# Spec 38 — Install Flutter

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-38-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# Spec: Script 38 -- Install Flutter

## Purpose

Installs a complete Flutter development environment: Flutter SDK (includes
Dart), Android Studio, Google Chrome (for Flutter web), and VS Code
Flutter/Dart extensions. Runs `flutter doctor` post-install to verify setup.

## Usage

```powershell
.\run.ps1                    # Install everything (default)
.\run.ps1 install            # Install Flutter SDK only
.\run.ps1 android            # Install Android Studio only
.\run.ps1 chrome             # Install Google Chrome only
.\run.ps1 extensions         # Install VS Code Flutter/Dart extensions only
.\run.ps1 doctor             # Run flutter doctor only
.\run.ps1 -Help              # Show usage
```

## What Gets Installed

| Component | Package | Method |
|-----------|---------|--------|
| Flutter SDK | `flutter` | Chocolatey |
| Dart SDK | (bundled) | Included with Flutter |
| Android Studio | `androidstudio` | Chocolatey |
| Google Chrome | `googlechrome` | Chocolatey |
| Dart extension | `Dart-Code.dart-code` | `code --install-extension` |
| Flutter extension | `Dart-Code.flutter` | `code --install-extension` |

## Post-Install

- Accepts Android SDK licenses automatically (`flutter doctor --android-licenses`)
- Runs `flutter doctor` to show environment status

## config.json

| Key | Type | Purpose |
|-----|------|---------|
| `enabled` | bool | Master toggle |
| `flutter.chocoPackageName` | string | Chocolatey package name |
| `flutter.alwaysUpgradeToLatest` | bool | Upgrade if already installed |
| `androidStudio.enabled` | bool | Toggle Android Studio install |
| `androidStudio.chocoPackageName` | string | Chocolatey package name |
| `chrome.enabled` | bool | Toggle Chrome install |
| `chrome.chocoPackageName` | string | Chocolatey package name |
| `vscodeExtensions.enabled` | bool | Toggle VS Code extension install |
| `vscodeExtensions.extensions` | array | Extension IDs to install |
| `postInstall.runFlutterDoctor` | bool | Run flutter doctor after install |
| `postInstall.acceptAndroidLicenses` | bool | Auto-accept Android licenses |

## Install Keywords

| Keyword | Script | Mode |
|---------|--------|------|
| `flutter` | 38 | `install` |
| `dart` | 38 | `install` |
| `mobile` | 38 | `install` |
| `install-flutter` | 38 | `install` |
| `flutter+android` | 38 | `android` |
| `flutter-extensions` | 38 | `extensions` |
| `flutter-doctor` | 38 | `doctor` |
| `mobile-dev` | 38 | (default -- all components) |
| `mobiledev` | 38 | (default -- all components) |

```powershell
.\run.ps1 install flutter            # SDK only
.\run.ps1 install flutter+android    # Android Studio only
.\run.ps1 install flutter-extensions # VS Code extensions only
.\run.ps1 install flutter-doctor     # Run flutter doctor only
.\run.ps1 install mobile-dev         # Full Flutter stack
```

## Helpers

| File | Functions | Purpose |
|------|-----------|---------|
| `flutter.ps1` | `Install-Flutter`, `Install-AndroidStudio`, `Install-Chrome`, `Install-FlutterVscodeExtensions`, `Invoke-FlutterDoctor` | Component installers |

## Resolved State

```json
{
  "flutterVersion": "3.x.x",
  "dartVersion": "Dart SDK version: 3.x.x",
  "channel": "stable",
  "timestamp": "2025-..."
}
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
