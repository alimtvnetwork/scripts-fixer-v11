Linux Installer Toolkit
=======================
let's start now 2026-04-26 (Asia/Kuala_Lumpur)

Phase 01 milestone: skeleton + shared helpers complete (v0.114.0).

Layout:
  _shared/         logger, pkg-detect, parallel, file-error, registry
  _shared/tests/   smoke.sh
  registry.json    list of scripts and their phase
  run.sh           root dispatcher (install|check|repair|uninstall|--list|-I)
  .installed/      per-script install markers (runtime)
  .resolved/       runtime resolved state
  .logs/           per-script logs

Resolution order per package: apt-get -> snap -> tarball/curl|sh -> none

Run smoke test:    bash scripts-linux/_shared/tests/smoke.sh
List scripts:      bash scripts-linux/run.sh --list

CODE RED rule: every file/path error logs exact path + reason via log_file_error.

Next phases:
  02 Detection layer hardening + resolve_install_method tests
  03 Foundational tools (nodejs, python, git, cpp, powershell)
  04 Editors + terminals
  05 Language runtimes
  06 SQL databases
  07 NoSQL + search
  08 Containers + orchestration
  09 AI tools
  10 Cross-platform UX
  11 Orchestrator
  12 Health-check + repair
  13 macOS port
  14 Docs + E2E tests
