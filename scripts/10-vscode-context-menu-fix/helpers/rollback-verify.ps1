# --------------------------------------------------------------------------
#  helpers/rollback-verify.ps1
#  Implements the verified-rollback workflow for Script 10.
#
#  Phases:
#    1. New-PreRollbackSnapshot   -- delegates to Script 54's
#       New-PreInstallSnapshot then renames the .reg file with a
#       'pre-rollback-' prefix so it cannot be confused with the
#       pre-install snapshot trail.
#    2. Invoke-RollbackInvariantBaseline -- runs both Script 10 check
#       passes (install state + repair invariants) WITHOUT mutating
#       the registry, captures the MISS action collector, and returns
#       a frozen snapshot of every (invariantCode, regPath, items)
#       tuple seen.
#    3. (caller performs the actual rollback / uninstall here)
#    4. Invoke-RollbackInvariantPost -- re-runs the same two check
#       passes against the now-mutated registry and returns the same
#       shape of frozen snapshot.
#    5. Write-RollbackVerificationReport -- prints a side-by-side
#       verdict block:
#         RESOLVED   : invariants present BEFORE that are now gone.
#         REGRESSED  : invariants NOT present before that appeared after
#                      (this should never happen for a clean rollback).
#         PERSISTED  : invariants present BEFORE that are STILL present
#                      after rollback (rollback failed to fix them).
#       Returns 0 (verified) when REGRESSED + PERSISTED are both empty,
#       1 otherwise. CODE RED: every persisted/regressed line includes
#       the exact regPath + invariantCode so the user can re-run check
#       or reg.exe query directly.
# --------------------------------------------------------------------------

Set-StrictMode -Version Latest

function New-PreRollbackSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Config,
        [Parameter(Mandatory)] [string] $ScriptDir
    )

    # Re-uses the existing snapshot helper (same paths, same .reg shape)
    # then renames the file so the audit trail clearly separates
    # pre-install snapshots from pre-rollback ones.
    $snapPath = New-PreInstallSnapshot -Config $Config -ScriptDir $ScriptDir
    $isSnapMissing = [string]::IsNullOrWhiteSpace($snapPath) -or -not (Test-Path -LiteralPath $snapPath)
    if ($isSnapMissing) {
        Write-Log ("Pre-rollback snapshot was NOT created (failure: New-PreInstallSnapshot returned no usable path; expected under " + (Join-Path $ScriptDir '.audit\snapshots') + ")") -Level "warn"
        return $null
    }
    $dir  = Split-Path -Parent $snapPath
    $leaf = Split-Path -Leaf   $snapPath  # snapshot-<stamp>.reg
    $renamed = "pre-rollback-" + $leaf
    $newPath = Join-Path $dir $renamed
    try {
        Rename-Item -LiteralPath $snapPath -NewName $renamed -ErrorAction Stop
    } catch {
        Write-Log ("Failed to rename pre-rollback snapshot: " + $snapPath + " -> " + $newPath + " (failure: " + $_.Exception.Message + "); leaving original name in place") -Level "warn"
        return $snapPath
    }
    return $newPath
}

function _Get-RollbackInvariantSnapshot {
    # Internal: resets the MISS collector, runs both check passes, then
    # returns a frozen list of [pscustomobject] keyed by invariantCode +
    # regPath. Read-only -- never mutates the registry.
    param(
        [Parameter(Mandatory)] $Config,
        [Parameter(Mandatory)] [string] $Phase   # 'before' | 'after'
    )
    Reset-Check10MissActions
    $a = Invoke-Script10MenuCheck            -Config $Config
    $b = Invoke-Script10RepairInvariantCheck -Config $Config
    $actions = Get-Check10MissActions

    $frozen = @()
    foreach ($x in $actions) {
        $frozen += [pscustomobject]@{
            phase         = $Phase
            invariantCode = $x.invariantCode
            edition       = $x.edition
            target        = $x.target
            regPath       = $x.regPath
            items         = @($x.items)
            reason        = $x.reason
            key           = ($x.invariantCode + '|' + $x.regPath)
        }
    }
    return [pscustomobject]@{
        phase     = $Phase
        actions   = $frozen
        totalPass = ($a.totalPass + $b.totalPass)
        totalMiss = ($a.totalMiss + $b.totalMiss)
    }
}

function Invoke-RollbackInvariantBaseline {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Config)
    Write-Log "" -Level "info"
    Write-Log "Rollback verification -- BEFORE phase: capturing current invariants..." -Level "info"
    return (_Get-RollbackInvariantSnapshot -Config $Config -Phase 'before')
}

function Invoke-RollbackInvariantPost {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Config)
    Write-Log "" -Level "info"
    Write-Log "Rollback verification -- AFTER phase: re-checking invariants post-rollback..." -Level "info"
    return (_Get-RollbackInvariantSnapshot -Config $Config -Phase 'after')
}

function Write-RollbackVerificationReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Before,
        [Parameter(Mandatory)] $After,
        [string] $SnapshotPath = ''
    )

    $beforeKeys = @{}
    foreach ($x in $Before.actions) { $beforeKeys[$x.key] = $x }
    $afterKeys = @{}
    foreach ($x in $After.actions)  { $afterKeys[$x.key]  = $x }

    $resolved  = @()
    $persisted = @()
    $regressed = @()
    foreach ($k in $beforeKeys.Keys) {
        if ($afterKeys.ContainsKey($k)) { $persisted += $beforeKeys[$k] }
        else                            { $resolved  += $beforeKeys[$k] }
    }
    foreach ($k in $afterKeys.Keys) {
        if (-not $beforeKeys.ContainsKey($k)) { $regressed += $afterKeys[$k] }
    }

    Write-Log "" -Level "info"
    Write-Log "================================  ROLLBACK VERIFICATION  ================================" -Level "warn"
    if ($SnapshotPath) {
        Write-Log ("  Pre-rollback snapshot : " + $SnapshotPath) -Level "info"
        Write-Log ("  Manual restore command: reg.exe import """ + $SnapshotPath + """") -Level "info"
    }
    Write-Log ("  BEFORE rollback : " + $Before.actions.Count + " invariant miss(es) (totalMiss=" + $Before.totalMiss + ")") -Level "info"
    Write-Log ("  AFTER  rollback : " + $After.actions.Count  + " invariant miss(es) (totalMiss=" + $After.totalMiss  + ")") -Level "info"
    Write-Log "-----------------------------------------------------------------------------------------" -Level "info"

    if ($resolved.Count -gt 0) {
        Write-Log ("  [RESOLVED]  " + $resolved.Count + " invariant(s) cleared by rollback:") -Level "success"
        foreach ($r in $resolved) {
            Write-Log ("              - [" + $r.invariantCode + "] " + $r.regPath + "   (edition=" + $r.edition + ", target=" + $r.target + ")") -Level "success"
        }
    } else {
        Write-Log "  [RESOLVED]  none (no invariant misses were present before rollback)" -Level "info"
    }

    if ($persisted.Count -gt 0) {
        Write-Log ("  [PERSISTED] " + $persisted.Count + " invariant(s) STILL present after rollback (rollback did not fix these):") -Level "error"
        foreach ($p in $persisted) {
            Write-Log ("              - [" + $p.invariantCode + "] " + $p.regPath) -Level "error"
            if ($p.items.Count -gt 0) { Write-Log ("                Items: " + ($p.items -join ', ')) -Level "error" }
            Write-Log ("                Verify : reg.exe query """ + $p.regPath + """") -Level "warn"
        }
    }

    if ($regressed.Count -gt 0) {
        Write-Log ("  [REGRESSED] " + $regressed.Count + " NEW invariant(s) appeared AFTER rollback (unexpected -- rollback introduced state):") -Level "error"
        foreach ($g in $regressed) {
            Write-Log ("              - [" + $g.invariantCode + "] " + $g.regPath) -Level "error"
            if ($g.items.Count -gt 0) { Write-Log ("                Items: " + ($g.items -join ', ')) -Level "error" }
            Write-Log ("                Verify : reg.exe query """ + $g.regPath + """") -Level "warn"
        }
    }

    Write-Log "-----------------------------------------------------------------------------------------" -Level "info"
    $isVerified = ($persisted.Count -eq 0) -and ($regressed.Count -eq 0)
    if ($isVerified) {
        Write-Log "  VERDICT     : VERIFIED -- post-rollback state matches expected (no PERSISTED, no REGRESSED)." -Level "success"
    } else {
        Write-Log "  VERDICT     : NOT VERIFIED -- see PERSISTED/REGRESSED list above. Re-run: .\run.ps1 check -ExitCodeMap" -Level "error"
    }
    Write-Log "==========================================================================================" -Level "warn"

    return [pscustomobject]@{
        verified  = $isVerified
        resolved  = $resolved
        persisted = $persisted
        regressed = $regressed
    }
}