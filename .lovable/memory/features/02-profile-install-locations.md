---
name: profile-install-locations
description: Per-profile install location matrix (C:\ system vs E:\dev-tool) -- must stay in sync between README, spec, and config.json
type: feature
---
# Profile install locations

Every profile in `scripts/profile/config.json` installs a mix of tools.
The root README and `spec/2025-batch/12-profiles.md` MUST present a
**per-profile install location table** with three columns:

| Tool | Where it lands | Why |

## Conventions

- **C:\Program Files / C:\Program Files (x86)** -> all `choco` steps
  (vlc, 7zip, winrar, xmind, googlechrome, wordweb-free, beyondcompare,
  vcredist-all, directx, directx-sdk, whatsapp). Choco does NOT relocate
  to E:\ -- documented as "system drive, no override".
- **E:\dev-tool\\<tool>** -> dev-runtimes installed by numbered scripts
  03/04/05/06 (nodejs, pnpm, python, golang) via `$env:DEV_DIR`.
  These respect `path` subcommand override.
- **%LOCALAPPDATA%** -> WhatsApp, GitHub Desktop, VS Code (per-user
  installs that do not honor a custom dir).
- **%USERPROFILE%\.ssh, \.gitconfig, \GitHub** -> git-compact inline
  helpers (`Setup-SshKey`, `Apply-DefaultGitConfig`, `Setup-GitHubDir`).
- **System registry (HKLM/HKCU)** -> `os hib-off`, Win11 classic
  context-menu restore (HKCU CLSID).

## Rule

When adding/removing a profile step, update **all three** in the same
commit:
1. `scripts/profile/config.json`
2. `spec/2025-batch/12-profiles.md` install-location table
3. `readme.md` per-profile H3 section table

If a step's location is non-obvious (e.g. choco flag override, env var),
note it in the table's "Why" column.
