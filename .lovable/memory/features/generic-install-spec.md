---
name: Generic install-script behavior spec (in design)
description: Cross-repo install script contract — strict tag mode vs main-branch mode vs versioned discovery (v1..v20 parallel). Spec NOT YET WRITTEN — awaiting 15-item checklist confirmation.
type: feature
---

# Generic Install Script Behavior — Specification (IN DESIGN)

## Status
🔄 **In Progress** — spec drafted as a checklist, awaiting user confirmation on 15 items before files are written.

## Purpose
A reusable contract any repo can adopt so its `install.ps1` / `install.sh` / `quick-install` / `release-install` / feature-specific installers all behave identically regarding:

1. Strict release-tag installation (no fallback)
2. Main-branch default install
3. Versioned-repo auto-discovery (`<prefix>-vN`)

## Core Rules (user-stated, non-negotiable)

1. **No tag → install from `main` branch** of the resolved repo.
2. **Tag/version explicitly given (flag, env var, or URL like `/releases/tag/X` or `/refs/tags/X`) → install ONLY that exact release.**
   - No fallback to `main`.
   - No hopping to `v1`, `v2`, `v3`, etc.
   - On failure → fail hard with clear error.
3. **Versioned-repo discovery** (only when no strict tag is given):
   - Probe `<prefix>-v1` .. `<prefix>-v20` in parallel.
   - Pick highest existing → auto-upgrade.
4. **Spec must be generic** — no hardcoded prefix or owner. Each repo declares its own.
5. **All names/tags/flags lowercase** (`v6`, never `V6`).

## Decided So Far (user confirmed in chat)

| Topic | Decision |
|-------|----------|
| Suffix pattern | `<prefix>-v<N>` lowercase |
| Discovery scope | v1..v20 fixed window (per latest user msg "it was v1 to v20") |
| Spec layout | Multi-file folder, split by section |
| Spec location | `spec/00-generic-install-script-behavior/` |

## Awaiting Confirmation (15-item checklist)

Posted to user; reply pending. See chat for full checklist. Key open questions:

- Item 6 — include current version in the v1..v20 probe, or skip it?
- Item 8 — probe via HTTP HEAD on `raw.githubusercontent.com/.../install.sh` OR `git ls-remote`?
- Item 9 — discovery action: (a) log only / (b) auto-upgrade to highest / (c) prompt user
- Item 10 — exact strict-mode triggers (flag + env var + URL patterns)

## Planned Spec Files (when confirmed)

```
spec/00-generic-install-script-behavior/
├── readme.md                       # overview + index
├── 01-release-tag-mode.md          # strict mode (no fallback)
├── 02-main-branch-mode.md          # default
├── 03-versioned-discovery.md       # v1..v20 parallel probe
├── 04-failure-handling.md          # hard-fail rules
├── 05-acceptance-criteria.md
└── 06-implementation-plan.md       # per-repo migration steps
```

## Relationship to Existing Spec

Supersedes / generalizes `spec/install-bootstrap/readme.md` (currently scripts-fixer-specific, uses current+30 probe). After this generic spec lands, `install-bootstrap` should be re-pointed to it as a concrete instance.

## Cross-Reference

- Existing implementation: `install.ps1`, `install.sh` in scripts-fixer
- Existing memory: `mem://features/install-bootstrap`
- Plan entry: `.lovable/plan.md` → "Generic install-script spec"
