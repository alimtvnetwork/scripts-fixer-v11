---
name: Windows user-mgmt shared helpers
description: scripts/os/helpers/_common.ps1 exposes Invoke-UserModify, Invoke-UserDelete, Invoke-PurgeHome (parity with um_user_modify/delete/purge_home on Unix). Used by edit-user.ps1, remove-user.ps1, edit-user-from-json.ps1, remove-user-from-json.ps1.
type: feature
---
Windows parity layer (added v0.208.0). All four user-management leaves call into
the shared helpers in scripts/os/helpers/_common.ps1 instead of duplicating
Get-LocalUser / Set-LocalUser / net.exe logic.

- Invoke-UserModify -Name <user> -Op <password|shell|comment|enable|disable|add-group|rm-group|rename> [-Value <v>] [-DryRun]
  shell op is a no-op on Windows (login shell is system-wide), logged at info level.
- Invoke-UserDelete -Name <user> [-DryRun] [-PassThru]
  Resolves ProfileList registry path BEFORE deletion so caller can purge after.
  -PassThru returns @{Success; ProfilePath; Sid}.
  Missing user is idempotent ok (returns Success=$true, ProfilePath="").
- Invoke-PurgeHome -ProfilePath <path> [-DryRun]
  CODE RED: every error includes the exact path. Missing path = idempotent ok.

JSON loaders apply records IN-PROCESS (no per-row leaf forking) and accept
the same shapes as the bash side: single object, array, { users: [...] },
plus bare-string list shorthand for remove-user-json.
