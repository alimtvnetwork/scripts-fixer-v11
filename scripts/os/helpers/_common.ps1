<#
.SYNOPSIS
    Common helpers shared by all os/* subcommand helpers.
#>

function Test-IsAdministrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Admin {
    param(
        [Parameter(Mandatory)][string]$ScriptPath,
        [string[]]$ForwardArgs = @(),
        [PSObject]$LogMessages
    )
    $isAdmin = Test-IsAdministrator
    if ($isAdmin) { return $true }

    $msg = "Administrator elevation required. Re-launching ..."
    if ($LogMessages -and $LogMessages.messages.adminRequired) {
        $msg = $LogMessages.messages.adminRequired
    }
    Write-Log $msg -Level "warn"

    # Pick pwsh (PS 7+) or powershell (PS 5.1) -- whichever is hosting us
    $hostExe = (Get-Process -Id $PID).Path
    if ([string]::IsNullOrWhiteSpace($hostExe)) {
        $hostExe = "powershell.exe"
    }

    $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$ScriptPath`"")
    foreach ($a in $ForwardArgs) {
        $argList += "`"$a`""
    }

    try {
        Start-Process -FilePath $hostExe -ArgumentList $argList -Verb RunAs -ErrorAction Stop | Out-Null
    } catch {
        $failMsg = "Failed to re-launch elevated. Run from an Administrator PowerShell. Path: $ScriptPath. Error: $($_.Exception.Message)"
        if ($LogMessages -and $LogMessages.messages.adminRelaunchFailed) {
            $failMsg = "$($LogMessages.messages.adminRelaunchFailed) Path: $ScriptPath. Error: $($_.Exception.Message)"
        }
        Write-Log $failMsg -Level "fail"
    }
    return $false
}

function Confirm-Action {
    param(
        [string]$Prompt = "Proceed? [y/N]: ",
        [switch]$AutoYes
    )
    if ($AutoYes) { return $true }
    Write-Host ""
    Write-Host "  $Prompt" -ForegroundColor Yellow -NoNewline
    $reply = Read-Host
    return ($reply -match '^(y|yes)$')
}

function Format-Bytes {
    param([long]$Bytes)
    $hasBytes = $Bytes -gt 0
    if (-not $hasBytes) { return "0" }
    $mb = [Math]::Round($Bytes / 1MB, 2)
    return "$mb"
}

function Format-Gb {
    param([long]$Bytes)
    if ($Bytes -le 0) { return "0" }
    return [Math]::Round($Bytes / 1GB, 2).ToString()
}

# =============================================================================
# Shared user-management helpers (Windows parity with scripts-linux/68-user-mgmt
# helpers/_common.sh: um_user_modify, um_user_delete, um_purge_home).
#
# These are extracted so edit-user.ps1, remove-user.ps1, edit-user-from-json.ps1
# and remove-user-from-json.ps1 all apply identical OS-level changes without
# re-implementing the Get-LocalUser / Set-LocalUser / net.exe branching, the
# dry-run shim, or the CODE RED file/path error reporting.
#
# Every helper:
#   * honours -DryRun by logging the intent only;
#   * logs success with Write-Log -Level "success" and failure with -Level "fail",
#     including the EXACT path/tool that failed (CODE RED rule);
#   * returns $true on success, $false on hard failure.
# =============================================================================

function Mask-Password {
    param([string]$Pw)
    if ([string]::IsNullOrEmpty($Pw)) { return "<none>" }
    $cap = [Math]::Min($Pw.Length, 8)
    return ('*' * $cap)
}

# Invoke-UserModify <name> <op> [args] -- single atomic edit.
#   Ops: password <pw> | shell <path> (no-op on Windows, logged as info) |
#        comment <text> | enable | disable | add-group <g> | rm-group <g> |
#        rename <newName>
function Invoke-UserModify {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('password','shell','comment','enable','disable','add-group','rm-group','rename')][string]$Op,
        [string]$Value = "",
        [switch]$DryRun
    )

    switch ($Op) {
        'password' {
            if ([string]::IsNullOrEmpty($Value)) {
                Write-Log "Invoke-UserModify password '$Name': empty password (failure: refusing to set blank)" -Level "fail"
                return $false
            }
            $masked = Mask-Password -Pw $Value
            if ($DryRun) { Write-Log "[dry-run] Set-LocalUser -Name $Name -Password <$masked>" -Level "info"; return $true }
            try {
                $sec = ConvertTo-SecureString $Value -AsPlainText -Force
                Set-LocalUser -Name $Name -Password $sec -ErrorAction Stop
                Write-Log "Password reset for '$Name' (masked: $masked)." -Level "success"
                return $true
            } catch {
                Write-Log "Failed to reset password for '$Name'. Reason: $($_.Exception.Message). Tool: Set-LocalUser" -Level "fail"
                return $false
            }
        }
        'shell' {
            # Windows local accounts have no per-user login shell; this is a Unix concept.
            Write-Log "shell change for '$Name' is a no-op on Windows (login shell is system-wide). Requested: '$Value'" -Level "info"
            return $true
        }
        'comment' {
            if ($DryRun) { Write-Log "[dry-run] net.exe user $Name /comment:`"$Value`"" -Level "info"; return $true }
            try {
                & net.exe user $Name "/comment:$Value" 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    Write-Log "Failed to set comment for '$Name'. Reason: net.exe exit=$LASTEXITCODE. Tool: net.exe user /comment" -Level "fail"
                    return $false
                }
                Write-Log "Set comment for '$Name'." -Level "success"
                return $true
            } catch {
                Write-Log "Failed to set comment for '$Name'. Reason: $($_.Exception.Message). Tool: net.exe user /comment" -Level "fail"
                return $false
            }
        }
        'enable' {
            if ($DryRun) { Write-Log "[dry-run] Enable-LocalUser -Name $Name" -Level "info"; return $true }
            try { Enable-LocalUser -Name $Name -ErrorAction Stop; Write-Log "Enabled '$Name'." -Level "success"; return $true }
            catch { Write-Log "Failed to enable '$Name'. Reason: $($_.Exception.Message). Tool: Enable-LocalUser" -Level "fail"; return $false }
        }
        'disable' {
            if ($DryRun) { Write-Log "[dry-run] Disable-LocalUser -Name $Name" -Level "info"; return $true }
            try { Disable-LocalUser -Name $Name -ErrorAction Stop; Write-Log "Disabled '$Name'." -Level "success"; return $true }
            catch { Write-Log "Failed to disable '$Name'. Reason: $($_.Exception.Message). Tool: Disable-LocalUser" -Level "fail"; return $false }
        }
        'add-group' {
            if ([string]::IsNullOrWhiteSpace($Value)) { Write-Log "Invoke-UserModify add-group '$Name': empty group" -Level "fail"; return $false }
            if ($DryRun) { Write-Log "[dry-run] Add-LocalGroupMember -Group $Value -Member $Name" -Level "info"; return $true }
            try {
                Add-LocalGroupMember -Group $Value -Member $Name -ErrorAction Stop
                Write-Log "Added '$Name' to '$Value'." -Level "success"
                return $true
            } catch {
                if ($_.Exception.Message -match "already a member") {
                    Write-Log "'$Name' already in '$Value' -- idempotent ok." -Level "info"
                    return $true
                }
                Write-Log "Failed to add '$Name' to '$Value'. Reason: $($_.Exception.Message). Tool: Add-LocalGroupMember" -Level "fail"
                return $false
            }
        }
        'rm-group' {
            if ([string]::IsNullOrWhiteSpace($Value)) { Write-Log "Invoke-UserModify rm-group '$Name': empty group" -Level "fail"; return $false }
            if ($DryRun) { Write-Log "[dry-run] Remove-LocalGroupMember -Group $Value -Member $Name" -Level "info"; return $true }
            try {
                Remove-LocalGroupMember -Group $Value -Member $Name -ErrorAction Stop
                Write-Log "Removed '$Name' from '$Value'." -Level "success"
                return $true
            } catch {
                if ($_.Exception.Message -match "was not found|not a member") {
                    Write-Log "'$Name' not in '$Value' -- idempotent ok." -Level "info"
                    return $true
                }
                Write-Log "Failed to remove '$Name' from '$Value'. Reason: $($_.Exception.Message). Tool: Remove-LocalGroupMember" -Level "fail"
                return $false
            }
        }
        'rename' {
            if ([string]::IsNullOrWhiteSpace($Value)) { Write-Log "Invoke-UserModify rename '$Name': empty new name" -Level "fail"; return $false }
            if ($DryRun) { Write-Log "[dry-run] Rename-LocalUser -Name $Name -NewName $Value" -Level "info"; return $true }
            try {
                Rename-LocalUser -Name $Name -NewName $Value -ErrorAction Stop
                Write-Log "Renamed '$Name' -> '$Value'." -Level "success"
                return $true
            } catch {
                Write-Log "Failed to rename '$Name' -> '$Value'. Reason: $($_.Exception.Message). Tool: Rename-LocalUser" -Level "fail"
                return $false
            }
        }
    }
}

# Invoke-UserDelete <name> [-DryRun]
# Deletes the local account. Resolves and returns the profile path via -PassThru
# so the caller can chain Invoke-PurgeHome. Removing a missing user is idempotent
# (returns $true, ProfilePath = "").
function Invoke-UserDelete {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$DryRun,
        [switch]$PassThru
    )

    $profilePath = ""
    $sid = ""
    $user = $null
    try { $user = Get-LocalUser -Name $Name -ErrorAction Stop } catch {
        Write-Log "User '$Name' not found -- nothing to delete (idempotent ok). Reason: $($_.Exception.Message). Path: HKLM:\SAM (local users)" -Level "warn"
        if ($PassThru) { return [PSCustomObject]@{ Success = $true; ProfilePath = ""; Sid = "" } }
        return $true
    }
    $sid = $user.SID.Value

    # Resolve the profile path BEFORE deleting so the caller can purge it after.
    try {
        $regKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"
        if (Test-Path $regKey) {
            $pp = (Get-ItemProperty $regKey -ErrorAction SilentlyContinue).ProfileImagePath
            if ($pp) { $profilePath = $pp }
        }
    } catch {}
    if ([string]::IsNullOrWhiteSpace($profilePath)) { $profilePath = "C:\Users\$Name" }

    if ($DryRun) {
        Write-Log "[dry-run] Remove-LocalUser -Name $Name (SID $sid)" -Level "info"
        if ($PassThru) { return [PSCustomObject]@{ Success = $true; ProfilePath = $profilePath; Sid = $sid } }
        return $true
    }

    try {
        Remove-LocalUser -Name $Name -ErrorAction Stop
        Write-Log "Removed local user '$Name' (SID $sid)." -Level "success"
    } catch {
        Write-Log "Failed to remove '$Name'. Reason: $($_.Exception.Message). Tool: Remove-LocalUser" -Level "fail"
        if ($PassThru) { return [PSCustomObject]@{ Success = $false; ProfilePath = $profilePath; Sid = $sid } }
        return $false
    }

    # Best-effort cleanup of the ProfileList registry stub; non-fatal.
    try {
        $regKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"
        if (Test-Path $regKey) { Remove-Item -Path $regKey -Recurse -Force -ErrorAction SilentlyContinue }
    } catch {}

    if ($PassThru) { return [PSCustomObject]@{ Success = $true; ProfilePath = $profilePath; Sid = $sid } }
    return $true
}

# Invoke-PurgeHome <profilePath> [-DryRun]
# Removes a profile/home folder. CODE RED: every error includes the exact path.
# Missing path = idempotent ok (returns $true with an info log).
function Invoke-PurgeHome {
    param(
        [Parameter(Mandatory)][string]$ProfilePath,
        [switch]$DryRun
    )
    if ([string]::IsNullOrWhiteSpace($ProfilePath)) {
        Write-Log "Invoke-PurgeHome: empty profile path (failure: nothing to purge)" -Level "fail"
        return $false
    }
    if ($DryRun) {
        Write-Log "[dry-run] Remove-Item -LiteralPath '$ProfilePath' -Recurse -Force  (DESTRUCTIVE)" -Level "info"
        return $true
    }
    if (-not (Test-Path -LiteralPath $ProfilePath)) {
        Write-Log "Profile folder not present at '$ProfilePath' -- nothing to purge (idempotent ok)." -Level "info"
        return $true
    }
    try {
        Remove-Item -LiteralPath $ProfilePath -Recurse -Force -ErrorAction Stop
        Write-Log "Deleted profile folder '$ProfilePath'." -Level "success"
        return $true
    } catch {
        Write-Log "Failed to delete profile folder. Path: $ProfilePath. Reason: $($_.Exception.Message). Tool: Remove-Item -Recurse -Force" -Level "fail"
        return $false
    }
}

# =============================================================================
# Set-SshFileAcl -- harden ACL on a .ssh\ dir or authorized_keys file so it
# matches OpenSSH for Windows StrictModes requirements:
#   * Inheritance disabled (no parent ACEs leak in).
#   * Only SYSTEM, Administrators, and the target user have access.
#   * Owner = target user (so the user can rotate keys without admin).
#
# CODE RED: every failure path logs the exact file path + the icacls.exe
# exit code AND its captured stdout/stderr so the operator can see the
# precise reason without re-running by hand.
# =============================================================================
function Set-SshFileAcl {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$User,
        [switch]$DryRun
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Log "Set-SshFileAcl: empty path (failure: refusing to harden nothing)" -Level "fail"
        return $false
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Log "Set-SshFileAcl: target does not exist. Path: $Path. Reason: cannot harden ACL on missing file/dir. Tool: icacls.exe" -Level "fail"
        return $false
    }
    if ($DryRun) {
        Write-Log "[dry-run] icacls '$Path' /inheritance:r /grant:r SYSTEM:F Administrators:F ${User}:F /setowner $User" -Level "info"
        return $true
    }

    # 1. Disable inheritance and remove inherited ACEs in one shot.
    $out = & icacls.exe "$Path" /inheritance:r 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Failed to disable ACL inheritance. Path: $Path. Reason: icacls exit=$LASTEXITCODE. Output: $($out -join ' '). Tool: icacls.exe /inheritance:r" -Level "fail"
        return $false
    }

    # 2. Grant only SYSTEM, Administrators, and the target user. /grant:r REPLACES.
    foreach ($principal in @("SYSTEM", "Administrators", $User)) {
        $out = & icacls.exe "$Path" /grant:r "${principal}:(F)" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to grant ACL to '$principal'. Path: $Path. Reason: icacls exit=$LASTEXITCODE. Output: $($out -join ' '). Tool: icacls.exe /grant:r" -Level "fail"
            return $false
        }
    }

    # 3. Strip every other principal (Authenticated Users, Everyone, Users, etc.)
    #    Best-effort -- /remove is a no-op if the principal is absent, so we don't
    #    fail the whole operation if any single removal returns non-zero.
    foreach ($strip in @("Authenticated Users", "Everyone", "Users")) {
        $null = & icacls.exe "$Path" /remove:g "$strip" 2>&1
    }

    # 4. Set owner to the target user so they can rotate keys without admin.
    $out = & icacls.exe "$Path" /setowner "$User" 2>&1
    if ($LASTEXITCODE -ne 0) {
        # Non-fatal: owner may already be correct, or user is the current shell user.
        Write-Log "Could not set owner to '$User' (continuing). Path: $Path. Reason: icacls exit=$LASTEXITCODE. Output: $($out -join ' '). Tool: icacls.exe /setowner" -Level "warn"
    }

    Write-Log "Hardened ACL on '$Path' (owner=$User; access=SYSTEM,Administrators,$User; no inheritance)." -Level "success"
    return $true
}
