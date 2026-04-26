# Cross-Platform Installer Plan — Ubuntu (priority) + macOS

**Created:** 2026-04-26
**Version target:** v0.114.0 (plan only — no code yet)
**Status:** Awaiting `next` to begin Phase 01

---

## Goal

Mirror the existing Windows PowerShell installer toolkit (55 scripts) for:

1. **Ubuntu / Debian Linux** — priority. Resolution order per package:
   `apt-get` → `snap` → official tarball / curl|sh fallback.
2. **macOS** — secondary. Resolution order:
   `brew` (formula) → `brew --cask` → official installer.

Where a package exists on Linux, the same Bash logic should also work on
macOS (with Homebrew swapped in for apt). When it cannot, fall back to the
macOS-specific path.

Parallel installation supported via `xargs -P` (Linux) / `parallel` or
background jobs (macOS), gated by a `--parallel N` flag.

---

## Design Principles (carried over from Windows toolkit)

1. One folder per script: `scripts-linux/NN-install-xxx/` and
   `scripts-macos/NN-install-xxx/`.
2. Each folder ships `run.sh`, `config.json`, `log-messages.json`,
   `readme.txt`.
3. Single root dispatcher: `run.sh` (Linux) and `run.sh` (macOS) — same
   verbs as Windows: `install`, `check`, `repair`, `uninstall`,
   `--list`, `-I <id>`.
4. Shared helpers under `scripts-linux/_shared/` and
   `scripts-macos/_shared/` (logger, package-detect, parallel-runner,
   file-error reporter — CODE RED rule preserved).
5. Tracking dirs reused: `.installed/`, `.resolved/`, `.logs/`.
6. Boolean prefix `is_` / `has_`. No bare `[ ! ]` chains — use named
   helper functions.
7. Every file/path error logs **exact path + reason** (CODE RED).

---

## Mapping of Windows scripts → Linux availability

Legend: ✅ apt | 🟦 snap | 🟧 tarball/curl | ❌ N/A on Linux

| # | Windows script | Linux strategy |
|---|----------------|----------------|
| 01 | VS Code | ✅ `code` via Microsoft apt repo / 🟦 `snap install code --classic` |
| 02 | Chocolatey/Winget | ❌ → replaced by apt itself |
| 03 | Node.js | ✅ NodeSource apt / 🟧 nvm |
| 04 | pnpm | 🟧 `curl -fsSL https://get.pnpm.io/install.sh \| sh -` |
| 05 | Python | ✅ `python3 python3-pip python3-venv` |
| 06 | Go | ✅ `golang-go` / 🟧 official tarball for latest |
| 07 | Git | ✅ `git` |
| 08 | GitHub Desktop | 🟧 shiftkey deb repo (community) |
| 09 | C++ toolchain | ✅ `build-essential gdb cmake` |
| 10 | VSCode context menu | ❌ Windows-only |
| 11 | VSCode settings sync | ✅ portable |
| 12 | All-dev-tools group | ✅ portable (orchestrator) |
| 14 | Winget | ❌ Windows-only |
| 15 | Windows tweaks | ❌ Windows-only |
| 16 | PHP | ✅ `php php-cli php-fpm` |
| 17 | PowerShell | ✅ Microsoft apt repo |
| 18 | MySQL | ✅ `mysql-server` |
| 19 | MariaDB | ✅ `mariadb-server` |
| 20 | PostgreSQL | ✅ `postgresql` |
| 21 | SQLite | ✅ `sqlite3` |
| 22 | MongoDB | ✅ MongoDB apt repo |
| 23 | CouchDB | ✅ Apache CouchDB apt repo |
| 24 | Redis | ✅ `redis-server` |
| 25 | Cassandra | ✅ Apache apt repo |
| 26 | Neo4j | ✅ Neo4j apt repo |
| 27 | Elasticsearch | ✅ Elastic apt repo |
| 28 | DuckDB | 🟧 GitHub release tarball |
| 29 | LiteDB | ❌ .NET-only — install via 39 |
| 31 | pwsh context menu | ❌ Windows-only (skipped) |
| 32 | DBeaver | ✅ DBeaver apt repo / 🟦 `snap install dbeaver-ce` |
| 33 | Notepad++ | ❌ → replaced by `gedit`/`kate`/`code` (skip or alias) |
| 34 | Sticky Notes | ❌ → use `xpad` or skip |
| 35 | gitmap | 🟧 portable bash port (TBD) |
| 36 | OBS | ✅ `obs-studio` PPA / 🟦 snap |
| 37 | Windows Terminal | ❌ → recommend `gnome-terminal`/`alacritty`/`kitty` |
| 38 | Flutter | 🟦 `snap install flutter --classic` / 🟧 tarball |
| 39 | .NET | ✅ Microsoft apt repo |
| 40 | Java | ✅ `openjdk-21-jdk` |
| 41 | Python libs | ✅ `pip install` (portable) |
| 42 | Ollama | 🟧 `curl -fsSL https://ollama.com/install.sh \| sh` |
| 43 | llama.cpp | 🟧 build from source / `apt install llama.cpp` (newer Ubuntu) |
| 44 | Rust | 🟧 `rustup` |
| 45 | Docker | ✅ Docker apt repo |
| 46 | Kubernetes | ✅ kubectl + kubeadm apt repo (already partially in `kubernetes/`) |
| 47 | Ubuntu font | ✅ `fonts-ubuntu` (no-op on Ubuntu) |
| 48 | ConEmu | ❌ → recommend tilix/terminator |
| 49 | WhatsApp | 🟦 `snap install whatsdesk` (3rd party) |
| 50 | OneNote | ❌ → recommend joplin (`snap`) |
| 51 | Lightshot | ❌ → `flameshot` (apt) |
| 52 | VSCode folder repair | ✅ portable |
| 53 | Script-fixer ctx menu | ❌ Windows-only |
| 54 | VSCode menu installer | ❌ Windows-only |
| 55 | Jenkins | ✅ Jenkins apt repo |

**Net Linux ports:** ~38 of 55 scripts have a real Linux equivalent.

---

## Phase plan — 14 steps

Each step is one `next` invocation. You can stop at any phase.

### Phase 01 — Repo skeleton + shared helpers
- Create `scripts-linux/`, `scripts-linux/_shared/` (logger.sh,
  pkg-detect.sh, parallel.sh, file-error.sh, registry.sh).
- Create `run.sh` dispatcher with verbs: `install`, `check`, `repair`,
  `uninstall`, `--list`, `-I <id>`, `--parallel N`.
- Create `scripts-linux/registry.json` (mirrors Windows numbering).
- Bump version to **v0.114.0**.

### Phase 02 — Detection layer
- `is_apt_available`, `is_snap_available`, `has_curl`, `is_root`,
  `get_ubuntu_version`, `get_arch`.
- Resolution function: `resolve_install_method <pkg>` → returns one of
  `apt|snap|tarball|none`.
- Unit-style smoke test under `scripts-linux/_shared/tests/`.

### Phase 03 — Group 1: foundational tools (5 scripts)
- 03-nodejs, 05-python, 07-git, 09-cpp, 17-powershell.
- All apt-first.

### Phase 04 — Group 2: editors + terminals (4 scripts)
- 01-vscode, 32-dbeaver, 36-obs, 47-ubuntu-font.
- Mix of apt + snap fallback.

### Phase 05 — Group 3: language runtimes (5 scripts)
- 04-pnpm, 06-go, 16-php, 39-dotnet, 40-java, 44-rust.

### Phase 06 — Group 4: SQL databases (5 scripts)
- 18-mysql, 19-mariadb, 20-postgresql, 21-sqlite, 28-duckdb.

### Phase 07 — Group 5: NoSQL + search (6 scripts)
- 22-mongodb, 23-couchdb, 24-redis, 25-cassandra, 26-neo4j,
  27-elasticsearch.

### Phase 08 — Group 6: container + orchestration (3 scripts)
- 45-docker, 46-kubernetes (consolidate with existing `kubernetes/`),
  55-jenkins.

### Phase 09 — Group 7: AI tools (3 scripts)
- 42-ollama, 43-llama-cpp, 41-python-libs.

### Phase 10 — Group 8: cross-platform UX tools (4 scripts)
- 11-vscode-settings-sync, 51-flameshot (Lightshot replacement),
  35-gitmap (portable port), 38-flutter.

### Phase 11 — Orchestrator (script 12 equivalent)
- `12-install-all-dev-tools` for Linux: profile-driven (`base`,
  `web`, `data`, `devops`, `ai`).
- Parallel installation via `xargs -P $N`.

### Phase 12 — Health + repair verbs
- `health-check.sh` (PATH sanity, disk, locale, kernel modules).
- `repair --only` parity with Windows script 10/54 model.

### Phase 13 — macOS port
- Duplicate folder tree to `scripts-macos/` swapping apt→brew,
  snap→cask. Reuse 100 % of dispatcher + helpers.
- `scripts-macos/_shared/pkg-detect.sh` resolves
  `brew|cask|pkg|none`.

### Phase 14 — Docs + tests
- Top-level `readme-linux.md`, `readme-macos.md`.
- Update root `install.sh` to detect OS and route.
- E2E smoke test in a Docker `ubuntu:22.04` container via GitHub
  Actions matrix.

---

## Open questions before I start Phase 01

1. **Ubuntu target version**: 22.04 LTS only, or 22.04 + 24.04 + Debian 12?
2. **Snap policy**: allow snap as a real fallback, or apt-only with a
   warning when missing?
3. **Sudo handling**: assume invoking user is in `sudoers`, or prompt
   per-script?
4. **Folder name**: keep `scripts-linux/` and `scripts-macos/` separate,
   or unify under `scripts/` with `_linux/` / `_macos/` subfolders per
   numbered script?

---

## Remaining tasks after this message

- Awaiting your `next` to execute **Phase 01 — Repo skeleton + shared helpers**.
- Open questions above (4) — answers will refine Phase 02.
- macOS port (Phase 13) deferred until Linux phases 01-12 are stable.

