<!-- spec-header:v1 -->
<div align="center">

<img src="../../../assets/icon-v1-rocket-stack.svg" alt="Script 54 — Test Harness" width="128" height="128"/>

# Script 54 — Test Harness

**Part of the Dev Tools Setup Scripts toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6#requirements)
[![Script](https://img.shields.io/badge/Script-54%20tests-8b5cf6)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/registry.json)
[![License](https://img.shields.io/badge/License-MIT-eab308)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.72.0-f97316)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/scripts/version.json)
[![Changelog](https://img.shields.io/badge/Changelog-Latest-ec4899)](https://github.com/alimtvnetwork/gitmap-v6/blob/main/changelog.md)
[![Repo](https://img.shields.io/badge/Repo-gitmap--v6-22c55e?logo=github&logoColor=white)](https://github.com/alimtvnetwork/gitmap-v6)

*Mandatory spec header — see [spec/00-spec-writing-guide](../../../spec/00-spec-writing-guide/readme.md).*

</div>

---

## Overview

Plain-PowerShell test runner for the VS Code menu installer. **Read-only**:
inspects the live registry against the path allow-list in `config.json` and
prints a colored pass/fail summary. Zero dependencies, no Pester.

This is the **subset** mirror of script 53's harness -- it verifies leaf
existence and the command template only. Script 54 does not emit
Shift-bypass twins, so cases 6 - 13 from script 53's spec do not apply
here.

## Prerequisites

- Windows 10 / 11
- Script 54 already installed:

  ```powershell
  .\run.ps1 -I 54 install                 # all enabled editions
  .\run.ps1 -I 54 install -Edition stable # one edition only
  ```

- Admin shell is **not** required for verify (read-only).

## Usage

From the repo root:

```powershell
# All enabled editions, all targets (file / directory / background)
.\scripts\54-vscode-menu-installer\tests\run-tests.ps1

# Same thing via the dispatcher
.\run.ps1 -I 54 verify

# One edition only
.\run.ps1 -I 54 verify -Edition stable

# Subset of targets
.\run.ps1 -I 54 verify -OnlyTargets file,directory

# Subset of cases
.\run.ps1 -I 54 verify -OnlyCases 1,4

# CI / log-friendly
.\run.ps1 -I 54 verify -NoColor

# Verbose (print every PASS line, not just FAIL)
.\run.ps1 -I 54 verify -Verbose
```

## Parameters

| Parameter      | Default                        | Notes                                                    |
|----------------|--------------------------------|----------------------------------------------------------|
| `Edition`      | `config.enabledEditions`       | Restrict to one edition (e.g. `stable` or `insiders`).   |
| `OnlyTargets`  | `file,directory,background`    | Subset of registry targets to test.                      |
| `OnlyCases`    | (all)                          | Array of case numbers, e.g. `-OnlyCases 1,4`.            |
| `NoColor`      | off                            | Disable ANSI colors (for log capture / CI).              |

## Exit codes

| Code | Meaning                                                              |
|------|----------------------------------------------------------------------|
| 0    | All cases passed                                                     |
| 1    | At least one assertion failed                                        |
| 2    | Pre-flight failed (config missing, no enabled editions to test)      |

## What each case verifies (per edition x per target)

| Case | Verifies                                                                                       |
|------|------------------------------------------------------------------------------------------------|
| 1    | The leaf key exists at the configured `registryPaths.<target>` path.                           |
| 2    | The leaf's `(Default)` REG_SZ value matches the configured `editions.<edition>.label`.         |
| 3    | A `command` subkey exists with a non-empty `(Default)` value.                                  |
| 4    | The `(Default)` command matches the expected template (direct dispatch OR confirm-launch wrapper, depending on `confirmBeforeLaunch.enabled`). For direct mode, also asserts the `%1` / `%V` placeholder tail. |
| 5    | Idempotency sanity -- no doubled-up siblings (e.g. `VSCodeVSCode`, `VSCode_1`) under the parent. |

## Mode auto-detection

The harness reads `config.confirmBeforeLaunch.enabled`:

- `false` (default) -> expects direct command lines like `"C:\...\Code.exe" "%1"`.
- `true` -> expects the wrapper:
  `pwsh ... confirm-launch.ps1 ... Invoke-ConfirmedCommand -CommandLine '<inner>' -Label '...' -CountdownSeconds N`.

You don't pass the mode to the harness -- it picks the right assertions automatically.
