<#
.SYNOPSIS
    os remove-user -- Delete a local Windows user.

.DESCRIPTION
    Usage:
      .\run.ps1 os remove-user <name> [flags]
      .\run.ps1 os remove-user --ask

    Flags:
      --purge-profile   Also delete C:\Users\<name> (DESTRUCTIVE)
      --purge-home      Alias of --purge-profile (Unix-friendly name)
      --yes             Skip the confirmation prompt
      --ask             Prompt interactively
      --dry-run         Print what would be removed

    Dry-run effect per flag (with --dry-run, the plan is printed first,
    the y/N confirmation prompt is BYPASSED, and every mutating call is
    logged as "[dry-run] <command>"; the host is NOT modified):
      <name>            would resolve account + profile path, then call
                        Remove-LocalUser -Name <name> (SID <sid>).
                        Absent account -> [WARN] "nothing to remove"
                        and exit 0 (idempotent); no mutation either way.
      --purge-profile   would 'Remove-Item -LiteralPath C:\Users\<name>
                        -Recurse -Force' AFTER account delete.
                        DESTRUCTIVE in real-run; in dry-run only the
                        Remove-Item command is logged.
      --purge-home      same as --purge-profile (alias only); same
                        dry-run line.
      --yes             no dry-run effect (skips the y/N confirmation;
                        under --dry-run the prompt is already skipped)
      --ask             prompts BEFORE the dry-run banner; collected
                        answers still drive the would-do log lines
      --dry-run         this flag itself; bypasses the y/N prompt, emits
                        the dry-run banner, and gates every Remove-
                        LocalUser / Remove-Item call
#>
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Argv = @())

$ErrorActionPreference = "Continue"
Set-StrictMode -Version Latest

$helpersDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$scriptDir  = Split-Path -Parent $helpersDir
$sharedDir  = Join-Path (Split-Path -Parent $scriptDir) "shared"

. (Join-Path $sharedDir "logging.ps1")
. (Join-Path $sharedDir "json-utils.ps1")
. (Join-Path $helpersDir "_common.ps1")
$promptHelper = Join-Path $helpersDir "_prompt.ps1"
if (Test-Path $promptHelper) { . $promptHelper }

$logMessages = Import-JsonConfig (Join-Path $scriptDir "log-messages.json")
$script:LogMessages = $logMessages
Initialize-Logging -ScriptName "Remove User"

$Name = $null; $purge = $false; $autoYes = $false
$hasAsk = $false; $hasDryRun = $false
$positional = @()
$i = 0
while ($i -lt $Argv.Count) {
    $a = $Argv[$i]
    switch -Regex ($a) {
        '^--purge-profile$|^--purge-home$' { $purge = $true }
        '^--yes$|^-y$'      { $autoYes = $true }
        '^--ask$'           { $hasAsk = $true }
        '^--dry-run$'       { $hasDryRun = $true }
        '^--' {
            Write-Log "Unknown flag: '$a'" -Level "fail"; Save-LogFile -Status "fail"; exit 64
        }
        default { $positional += $a }
    }
    $i++
}
if ($positional.Count -ge 1) { $Name = $positional[0] }

if ($hasAsk -and (Get-Command Read-PromptString -ErrorAction SilentlyContinue)) {
    if ([string]::IsNullOrWhiteSpace($Name)) { $Name = Read-PromptString -Prompt "Username to remove" -Required }
    $purge = Confirm-Prompt -Prompt "Also delete C:\Users\$Name profile folder?"
}

if ([string]::IsNullOrWhiteSpace($Name)) {
    Write-Log "Missing <name>. Usage: .\run.ps1 os remove-user <name> [flags]" -Level "fail"
    Save-LogFile -Status "fail"; exit 2
}

if ($hasDryRun) {
    Write-Host ""
    Write-Host "  DRY-RUN -- would remove:" -ForegroundColor Cyan
    Write-Host "    User    : $Name"
    if ($purge) { Write-Host "    Profile : C:\Users\$Name  (DESTRUCTIVE)" -ForegroundColor Yellow }
    Write-Host ""
    Save-LogFile -Status "ok"; exit 0
}

if (-not $autoYes) {
    $confirm = Confirm-Action -Prompt "Delete local user '$Name'? [y/N]: "
    if (-not $confirm) {
        Write-Log "Cancelled by user." -Level "warn"
        Save-LogFile -Status "ok"; exit 0
    }
}

$forwardArgs = @($Name) + ($Argv | Where-Object { $_ -ne "--ask" })
if (-not ($forwardArgs -contains "--yes")) { $forwardArgs += "--yes" }
$isAdminOk = Assert-Admin -ScriptPath $MyInvocation.MyCommand.Definition -ForwardArgs $forwardArgs -LogMessages $logMessages
if (-not $isAdminOk) { Save-LogFile -Status "fail"; exit 1 }

# Delegate to shared helpers (parity with um_user_delete + um_purge_home).
$result = Invoke-UserDelete -Name $Name -PassThru
if (-not $result.Success) { Save-LogFile -Status "fail"; exit 1 }

if ($purge) {
    if (-not (Invoke-PurgeHome -ProfilePath $result.ProfilePath)) {
        Save-LogFile -Status "fail"; exit 1
    }
}

Save-LogFile -Status "ok"
exit 0
