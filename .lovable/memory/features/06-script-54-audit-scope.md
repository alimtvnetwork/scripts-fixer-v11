---
name: Script 54 audit log carries resolved scope
description: Every audit JSONL event + summary + change-report row in scripts/54-vscode-menu-installer stamps the resolved Windows registry scope (CurrentUser | AllUsers) so auditors can tell which hive was touched
type: feature
---
## Audit log carries the resolved Windows registry scope

Every JSONL line in `scripts/54-vscode-menu-installer/.audit/audit-*.jsonl`
now carries a `scope` field, and so does the aggregated summary printed
at the end of install / uninstall / repair / rollback / sync runs. This
lets an auditor tell -- without cross-referencing -- whether a key was
written to `HKCU\Software\Classes\…` (CurrentUser) or
`HKLM\Software\Classes\…` (AllUsers).

### How it is wired
- `helpers/audit-log.ps1` keeps a module-scope `$script:AuditScope`
  (`CurrentUser` | `AllUsers` | `unknown`).
- `Initialize-RegistryAudit` accepts an optional `-Scope` parameter and
  stamps it on the `session-start` header line.
- `Set-RegistryAuditScope -Scope <s>` late-binds the scope when audit
  init runs BEFORE scope resolution (install.ps1, sync.ps1). It also
  drops a `scope-set` marker line so the JSONL itself records WHEN the
  scope became known.
- `Write-RegistryAuditEvent` writes `scope` on every `add`/`remove`/
  `skip-absent`/`fail` record.
- `Get-RegistryAuditSummary` exposes `.scope` on the summary object and
  on every `.added/.removed/.skipped/.failed` row (falls back to module
  scope for legacy lines that pre-date this feature).
- `helpers/vscode-check.ps1::Write-RegistryAuditReport` prints the
  resolved scope in the change-report banner and prefixes every per-row
  line with `[scope/edition/target]`.

### Caller wiring (one-liner per flow)
| Flow         | When scope becomes available | Wiring                                    |
|--------------|------------------------------|-------------------------------------------|
| install.ps1  | after audit init             | `Set-RegistryAuditScope -Scope $resolvedScope` |
| sync.ps1     | after audit init             | `Set-RegistryAuditScope -Scope $resolvedScope` |
| uninstall.ps1| before audit init            | `Initialize-RegistryAudit ... -Scope $resolvedScope` |
| repair.ps1   | before audit init            | `Initialize-RegistryAudit ... -Scope $resolvedScope` |
| rollback     | n/a -- alias for uninstall via run.ps1 | inherits uninstall wiring |

Built: v0.129.0. Backwards compatible -- old audit JSONL files without
a `scope` field still parse cleanly (summary fills with `'unknown'` /
the module-scope value).