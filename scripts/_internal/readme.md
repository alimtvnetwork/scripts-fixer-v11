<!-- spec-header:v1 -->
<div align="center">

<img src="../../assets/icon-v1-rocket-stack.svg" alt="Internal Maintenance Scripts" width="128" height="128"/>

# `_internal/` — Repo Maintenance Scripts

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Scope-internal-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.72.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../../spec/00-spec-writing-guide/readme.md).*

</div>

---

## Overview

`_internal/` — repo maintenance scripts

These are NOT user-facing dev tools. They're maintenance scripts the project
itself uses to keep generated docs / metadata in sync, plus CI quality gates.
None of them are wired into the registry, the dispatcher, or the keyword map.

## generate-registry-summary.cjs

Auto-regenerates `spec/script-registry-summary.md` from the live data in:

- `scripts/registry.json`             -- numeric ID -> folder mapping
- `scripts/<folder>/config.json`      -- per-script name / desc / chocoPackage / validModes
- `scripts/shared/install-keywords.json` -- keyword -> [script ids] + per-keyword mode overrides

### Run it

```bash
node scripts/_internal/generate-registry-summary.cjs
```

Output is written to `spec/script-registry-summary.md` (overwrites in place).
The script also prints a one-line summary on stdout, e.g.:

```
Wrote /.../spec/script-registry-summary.md
  51 scripts, 329 keywords, 73 mode entries, 47 combos, 25 subcommand keywords
```

### When to re-run

- After adding / removing / renaming a script folder (and updating `registry.json`)
- After editing `scripts/shared/install-keywords.json` (new keywords or modes)
- After editing a script's `config.json` (name / desc / validModes / defaultMode change)

### Auto-wired (since v0.40.3)

You normally **don't need to run this manually**:

- **Local**: `bump-version.ps1` invokes the generator automatically after writing the new version (skipped with a warning if Node is missing).
- **CI**: `.github/workflows/release.yml` runs the generator on every tag push and **fails the release** if the regenerated file differs from what's committed (drift detection).

Run it manually only when you've edited registry / config / keyword sources and want to preview the regenerated summary before bumping.

### What the generator pulls

| Source field                       | Where it shows up                              |
|------------------------------------|------------------------------------------------|
| `registry.scripts[id]`             | Folder column + headings                       |
| `config.json` top-level or 1-deep `name`        | Script heading (e.g. "Script 16: phpMyAdmin") |
| `config.json` `desc` / `description`            | "Description" line                             |
| `config.json` `chocoPackage` / `chocoPackageName` | "Choco package" line                         |
| `config.json` `validModes`         | "Valid Modes" line under mode mappings         |
| `config.json` `defaultMode`        | "Default Mode" line under mode mappings        |
| `install-keywords.json` `keywords` | Per-script keyword list + Combo Keywords table |
| `install-keywords.json` `modes`    | Per-script Mode Mappings table                 |

Subcommand-style keyword targets (`"os:clean"`, `"profile:base"`, etc.) are
collected separately into a "Subcommand Keywords" section -- they don't
correspond to numeric script IDs in the registry.

### Why CommonJS (`.cjs`)

The repo's `package.json` declares `"type": "module"`, so `.js` files would
be parsed as ESM. This script uses `require()` for synchronous file IO and
zero-dependency simplicity, so it lives as `.cjs`.

---

## lint-config-schemas.cjs

Validates every `scripts/<folder>/config.json` against the project schema.
Catches real bugs (FAIL -- blocks CI release) and drift (WARN -- advisory).

### Run it

```bash
node scripts/_internal/lint-config-schemas.cjs
```

Exit codes: `0` (no FAIL, release proceeds), `1` (FAIL rows, release blocked),
`2` (linter crashed). GitHub Actions annotations emitted automatically.

### Wired in CI

`.github/workflows/release.yml` runs the linter after the registry-summary
drift check. FAIL rows abort the release.

### Full spec

See `spec/lint-config-schemas/readme.md` for rules, schema discrimination,
output format, and how to extend.
