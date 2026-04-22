<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Spec 01 — Vscode Project Manager Sync" width="128" height="128"/>

# Spec 01 — Vscode Project Manager Sync

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-01-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.70.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../00-spec-writing-guide/readme.md).*

</div>

---

# 01 - VS Code Project Manager Sync (`run.ps1 scan <path>`)

## Overview

Walks a root directory, discovers project folders, and **upserts** them into
the VS Code Project Manager extension's `projects.json` so they show up in
the `alefragnani.project-manager` sidebar.

- Single command: `run.ps1 scan <path> [flags]`
- JSON-only storage (no DB) -- the VS Code `projects.json` IS the source of truth.
- Atomic writes (temp file + rename) -- never corrupts `projects.json`.
- Preserves entries we did not add (and per-entry fields we don't manage:
  `paths`, `tags`, `enabled`, `profile`).
- **Never opens VS Code.** This command only syncs the JSON file.

The `gitmap`-CLI integration and any `gitmap code <alias>` behavior are
**out of scope** for this spec by user decision (2026-04-21). This file
documents only the `scan` command.

## Command

```powershell
.\run.ps1 scan <root-path>                  # walk <root-path>, upsert into projects.json
.\run.ps1 scan <root-path> --depth 4        # custom recursion depth (default 5)
.\run.ps1 scan <root-path> --dry-run        # preview adds/updates, write nothing
.\run.ps1 scan <root-path> --json <file>    # override target projects.json path
.\run.ps1 scan --help                       # show help
```

If `<root-path>` is omitted, the current working directory is used.

## Flags

| Flag             | Description                                                | Default |
|------------------|------------------------------------------------------------|---------|
| `--depth N`      | Max directory recursion depth                              | `5`     |
| `--dry-run`      | Show what would change; do not write `projects.json`       | off     |
| `--json <path>`  | Override target `projects.json` (testing / non-default)    | OS auto |
| `--include-hidden` | Walk into folders starting with `.`                      | off     |
| `--help`         | Show help and exit                                         |         |

## Project Detection

A folder is treated as a project when it contains **any** of:

- `.git/` (Git repository root)
- `package.json`
- `pyproject.toml` / `requirements.txt` / `setup.py`
- `Cargo.toml`
- `go.mod`
- `composer.json`
- `pom.xml` / `build.gradle` / `build.gradle.kts`
- `*.csproj` / `*.sln`
- `Gemfile`
- `.lovable/` (Lovable project marker)

Once a folder qualifies as a project, the walker does **not** recurse into it
(prevents nested `node_modules`-style noise). Hidden folders (`.git`, `.idea`,
`node_modules`, `vendor`, `dist`, `build`, `target`, `.next`, `.venv`, `venv`,
`__pycache__`) are skipped unless `--include-hidden` is passed.

## VS Code `projects.json` Location

| OS      | Path                                                                                   |
|---------|----------------------------------------------------------------------------------------|
| Windows | `%APPDATA%\Code\User\globalStorage\alefragnani.project-manager\projects.json`          |
| macOS   | `~/Library/Application Support/Code/User/globalStorage/alefragnani.project-manager/projects.json` |
| Linux   | `~/.config/Code/User/globalStorage/alefragnani.project-manager/projects.json`          |

If the file or its parent directory does not exist, the script creates them
and seeds the file with `[]`.

## `projects.json` Schema

Confirmed from the user-supplied sample. The file is a JSON array; each entry:

```json
{
  "name": "atto-property",
  "rootPath": "d:\\wp-work\\riseup-asia\\atto-property",
  "paths": [],
  "tags": [],
  "enabled": true,
  "profile": ""
}
```

Field handling on upsert:

| Field      | On insert (new entry)             | On update (existing `rootPath`)     |
|------------|-----------------------------------|-------------------------------------|
| `name`     | Folder basename                   | **Preserved** (user may have aliased it) |
| `rootPath` | Absolute, normalized              | Match key -- never rewritten        |
| `paths`    | `[]`                              | Preserved                           |
| `tags`     | `[]`                              | Preserved                           |
| `enabled`  | `true`                            | Preserved                           |
| `profile`  | `""`                              | Preserved                           |

`rootPath` matching is **case-insensitive on Windows**, case-sensitive on
macOS / Linux. Trailing slashes are stripped before compare.

## Atomic Write Algorithm

1. Read the current `projects.json` (or `[]` if missing).
2. Build the upserted array in memory.
3. Serialize to JSON (UTF-8, no BOM, `Depth = 10`, indented with tabs to match
   the VS Code Project Manager style).
4. Write the bytes to `projects.json.tmp-<pid>-<ticks>` in the same directory.
5. `Move-Item -Force` the temp file over `projects.json`.
6. On any error, the temp file is deleted and the original is left untouched.

## Output

```
  Scripts Fixer v0.50.0
  Scan: VS Code Project Manager Sync
  ==================================

  Root        : D:\wp-work\riseup-asia
  Target JSON : C:\Users\Alim\AppData\Roaming\Code\User\globalStorage\alefragnani.project-manager\projects.json
  Depth       : 5
  Mode        : write

  [scan ] D:\wp-work\riseup-asia\atto-property              (git, node)
  [scan ] D:\wp-work\riseup-asia\category-forge             (git, node)
  ...

  Summary
  -------
    discovered : 14
    added      :  3
    updated    :  0    (already present, no field change)
    preserved  : 11    (existing entries we did not touch)
    skipped    :  0
    written to : C:\Users\Alim\AppData\Roaming\...\projects.json
```

## Acceptance Criteria

| # | Behavior                                                                  |
|---|---------------------------------------------------------------------------|
| 1 | `.\run.ps1 scan D:\code` upserts every discovered project; never opens VS Code |
| 2 | Re-running is idempotent -- no duplicates by `rootPath`                   |
| 3 | Existing entries we did not add are preserved verbatim                    |
| 4 | Existing `name`, `tags`, `paths`, `enabled`, `profile` are preserved on update |
| 5 | File writes are atomic (temp + rename); aborted runs never corrupt JSON   |
| 6 | Works on Windows / macOS / Linux paths                                    |
| 7 | `--dry-run` prints planned changes and writes nothing                     |
| 8 | The string `git map` (with a space) appears nowhere in code, help, or logs |
| 9 | Help text is reachable via `.\run.ps1 scan --help`                        |

## Out of Scope (this spec)

- `gitmap` CLI subcommand (`gitmap code`, `gitmap scan`, etc.)
- SQLite storage layer
- Auto-opening VS Code
- Multi-root (`paths`) authoring
- Auto-deriving `tags` (we leave `tags` alone on update; on insert they are `[]`)

## File Layout

```
scripts/scan/
  run.ps1                # dispatcher
  config.json            # detection markers, ignore list, depth
  log-messages.json      # banner + status strings
  helpers/
    vscode-projects.ps1  # locate / read / atomic-write projects.json
    walker.ps1           # directory walk + project detection
spec/01-vscode-project-manager-sync/
  readme.md              # this file
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
