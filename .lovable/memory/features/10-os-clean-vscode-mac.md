---
name: os clean-vscode-mac (macOS VS Code integration cleanup)
description: bash script under scripts/os/helpers/mac/clean-vscode-mac.sh + dispatcher action 'clean-vscode-mac' in scripts/os/run.ps1; surgical removal of Services / code CLI symlink / LaunchServices / login items + LaunchAgents with plan-then-prompt + audit JSONL
type: feature
---
## macOS VS Code integration cleanup

New action: `.\run.ps1 os clean-vscode-mac [flags]`

Implementation: `scripts/os/helpers/mac/clean-vscode-mac.sh` (bash, runs
on vanilla macOS without pwsh). The PowerShell dispatcher in
`scripts/os/run.ps1` recognizes the action, refuses cleanly on non-Darwin
(directs Windows users to script 54 instead), and shells out to the bash
helper.

### Surfaces (multi-select; default = ALL on)
| Flag                | Targets |
|---------------------|---------|
| `--services`        | `~/Library/Services/*VSCode*.workflow`, `*Visual Studio Code*.workflow`, `*Open*Code*.workflow` (and `/Library/Services/*` when root). |
| `--code-cli`        | `/usr/local/bin/code` and `/opt/homebrew/bin/code` -- only when the symlink target points at a Code.app bundle (or is a broken link). |
| `--launchservices`  | `lsregister -u` for every Code.app bundle found in `/Applications` and `~/Applications`. |
| `--loginitems`      | `~/Library/LaunchAgents/*vscode*.plist` (+ /Library when root) AND System Events login items whose path contains `Visual Studio Code.app`. `launchctl unload` first, then `rm`. |
| `--all`             | Re-enable all four surfaces. |

Passing ANY explicit `--<surface>` flag turns OFF the other three (so
`--services` alone means "ONLY services"). This is the surgical default.

### Scope (Auto-detect, no -Scope flag on macOS)
- `~/Library` is ALWAYS swept (CurrentUser writes, no sudo).
- `/Library` is swept ONLY when running as root AND the target dir is
  writable. Non-root runs SKIP `/Library` and log it as info -- never
  silently fail-and-claim-success.

### Safety: plan-then-prompt
1. Build plan -> enumerate every concrete target (no side effects).
2. Print plan grouped by surface with absolute paths + total count.
3. Prompt `[y/N]` (default N) read from `/dev/tty` so it works under
   pipes. `--yes` skips the prompt; `--dry-run` prints the plan and
   exits 0 without prompting.
4. Apply -- each action writes a JSONL record to the audit log.

### Verbosity
`--quiet` (totals + failures only), default normal, `--debug` (per-target
diagnostic lines). Mirrors script-54 contract; failures are NEVER suppressed.

### Audit log
`$HOME/Library/Logs/lovable-toolkit/clean-vscode-mac/<ts>.jsonl` -- one
`session-start` record + one `{op, surface, target, reason, ts}` record
per action + `session-end` with `removed=N failed=N`.

### Exit codes
- 0 -- success or dry-run
- 1 -- user aborted at prompt (or no tty available)
- 2 -- usage error (bad flag, conflicting flags, not on macOS, bash missing)
- 3 -- one or more removal actions failed (audit log has the per-target reasons)

### CODE RED compliance
Every file/path error includes the EXACT path AND the failure reason
(errno text or the failing command's stderr).

### Ownership detection (v0.134.0)
No candidate is added to the plan unless an ownership probe passes.
Verifiers (in `clean-vscode-mac.sh`):
- `verify_workflow`: reads `Contents/Info.plist` `CFBundleIdentifier` via
  `/usr/libexec/PlistBuddy`; accepts `com.microsoft.VSCode*` or any id
  containing `vscode`/`microsoft.code`. Fallback: greps
  `Contents/document.wflow` for `Visual Studio Code.app` /
  `com.microsoft.VSCode`. Filename-only matches are REJECTED.
- `verify_code_cli`: resolves the symlink with `python3 os.path.realpath`
  (macOS `readlink` lacks `-f`); accepts only when the resolved target is
  inside `Visual Studio Code.app/Contents/Resources/app/bin/code` (or a
  `Code.app` / `VSCode` variant). Broken links: accept only when the
  dangling target string still references VS Code. Regular files: accept
  only when first 4 KB contains `Visual Studio Code` /
  `com.microsoft.VSCode` / `VSCODE_`.
- `verify_code_app`: requires `CFBundleIdentifier` to match
  `com.microsoft.VSCode*` (incl. Insiders, Exploration).
- `verify_launch_agent`: requires `Label`, `Program`, or
  `ProgramArguments[0]` to reference `com.microsoft.VSCode` or a
  `Visual Studio Code.app` path.
- Login items: AppleScript filter requires path to contain
  `Visual Studio Code.app` / `Visual Studio Code - Insiders.app`;
  non-matches logged at debug level.

Rejections always log `[WARN] Skip <path> (failure: <reason>)` with the
EXACT path and the EXACT signal that failed (e.g. `CFBundleIdentifier='com.acme.Other'`).

All log helpers write to **stderr** so the planners' stdout (parsed by
`mapfile` into the plan array) stays free of log lines.

There is intentionally **no `--no-verify` escape hatch** -- the whole
point of detection is that the user asked for a tool that will not
delete unrelated items.

Built: v0.134.0.