<#
.SYNOPSIS
    os edit-user -- Modify a local Windows user.

.DESCRIPTION
    Usage:
      .\run.ps1 os edit-user <name> [flags]
      .\run.ps1 os edit-user --ask

    Flags:
      --rename <newName>            Rename the local account
      --reset-password <newPass>    Reset the password (plain CLI -- accepted risk)
      --promote                     Add to local 'Administrators'
      --demote                      Remove from 'Administrators' (keeps 'Users')
      --add-group <name>            Add to a local group (repeatable via comma list)
      --remove-group <name>         Remove from a local group (repeatable via comma list)
      --enable | --disable          Enable / disable the account
      --comment <text>              Set the account comment (we use this for email)
      --ask                         Prompt interactively
      --dry-run                     Print actions, change nothing
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
Initialize-Logging -ScriptName "Edit User"

# ---- Parse ----
$Name = $null; $newName = $null; $newPass = $null; $comment = $null
$promote = $false; $demote = $false
$enable = $false; $disable = $false
$addGroups = @(); $removeGroups = @()
$hasAsk = $false; $hasDryRun = $false
$positional = @()

$i = 0
while ($i -lt $Argv.Count) {
    $a = $Argv[$i]
    switch -Regex ($a) {
        '^--rename$'         { $i++; if ($i -lt $Argv.Count) { $newName = $Argv[$i] } }
        '^--reset-password$' { $i++; if ($i -lt $Argv.Count) { $newPass = $Argv[$i] } }
        '^--promote$'        { $promote = $true }
        '^--demote$'         { $demote = $true }
        '^--enable$'         { $enable = $true }
        '^--disable$'        { $disable = $true }
        '^--comment$'        { $i++; if ($i -lt $Argv.Count) { $comment = $Argv[$i] } }
        '^--add-group$'      { $i++; if ($i -lt $Argv.Count) { $addGroups += ($Argv[$i] -split ',') } }
        '^--remove-group$'   { $i++; if ($i -lt $Argv.Count) { $removeGroups += ($Argv[$i] -split ',') } }
        '^--ask$'            { $hasAsk = $true }
        '^--dry-run$'        { $hasDryRun = $true }
        '^--' {
            Write-Log "Unknown flag: '$a'" -Level "fail"
            Save-LogFile -Status "fail"; exit 64
        }
        default { $positional += $a }
    }
    $i++
}
if ($positional.Count -ge 1) { $Name = $positional[0] }

if ($hasAsk -and (Get-Command Read-PromptString -ErrorAction SilentlyContinue)) {
    if ([string]::IsNullOrWhiteSpace($Name)) { $Name = Read-PromptString -Prompt "Username to edit" -Required }
    $newName = Read-PromptString -Prompt "Rename to (blank = keep)"
    $resetAns = Confirm-Prompt -Prompt "Reset password?"
    if ($resetAns) { $newPass = Read-PromptSecret -Prompt "New password" -Required }
    $roleAns = Read-PromptString -Prompt "Role change [promote/demote/none]"
    if ($roleAns -match '^(?i)promote') { $promote = $true }
    if ($roleAns -match '^(?i)demote')  { $demote  = $true }
}

if ([string]::IsNullOrWhiteSpace($Name)) {
    Write-Log "Missing <name>. Usage: .\run.ps1 os edit-user <name> [flags]" -Level "fail"
    Save-LogFile -Status "fail"; exit 2
}
if ($promote -and $demote) {
    Write-Log "Both --promote and --demote given; aborting." -Level "fail"
    Save-LogFile -Status "fail"; exit 64
}
if ($enable -and $disable) {
    Write-Log "Both --enable and --disable given; aborting." -Level "fail"
    Save-LogFile -Status "fail"; exit 64
}

# ---- Plan summary ----
$planLines = @()
if ($newName)              { $planLines += "rename '$Name' -> '$newName'" }
if ($newPass)              { $planLines += "reset password (masked: $('*' * [Math]::Min($newPass.Length,8)))" }
if ($promote)              { $planLines += "add to Administrators" }
if ($demote)               { $planLines += "remove from Administrators" }
if ($enable)               { $planLines += "enable account" }
if ($disable)              { $planLines += "disable account" }
if ($addGroups.Count)      { $planLines += "add groups: $($addGroups -join ', ')" }
if ($removeGroups.Count)   { $planLines += "remove groups: $($removeGroups -join ', ')" }
if ($null -ne $comment)    { $planLines += "set comment: '$comment'" }
if (-not $planLines.Count) {
    Write-Log "No changes requested. Use --help for flags." -Level "warn"
    Save-LogFile -Status "ok"; exit 0
}

if ($hasDryRun) {
    Write-Host ""
    Write-Host "  DRY-RUN -- would edit '$Name':" -ForegroundColor Cyan
    foreach ($p in $planLines) { Write-Host "    - $p" }
    Write-Host ""
    Save-LogFile -Status "ok"; exit 0
}

$forwardArgs = @($Name) + ($Argv | Where-Object { $_ -ne "--ask" })
$isAdminOk = Assert-Admin -ScriptPath $MyInvocation.MyCommand.Definition -ForwardArgs $forwardArgs -LogMessages $logMessages
if (-not $isAdminOk) { Save-LogFile -Status "fail"; exit 1 }

# ---- Verify user exists ----
$user = $null
try { $user = Get-LocalUser -Name $Name -ErrorAction Stop } catch {
    Write-Log "User '$Name' not found. Failure: $($_.Exception.Message). Path: HKLM:\SAM (local users)" -Level "fail"
    Save-LogFile -Status "fail"; exit 1
}

# ---- Apply ----
if ($newPass) {
    try {
        $sec = ConvertTo-SecureString $newPass -AsPlainText -Force
        Set-LocalUser -Name $Name -Password $sec -ErrorAction Stop
        Write-Log "Password reset for '$Name'." -Level "success"
    } catch {
        Write-Log "Failed to reset password for '$Name': $($_.Exception.Message)" -Level "fail"
        Save-LogFile -Status "fail"; exit 1
    }
}
if ($enable)  { try { Enable-LocalUser  -Name $Name -ErrorAction Stop; Write-Log "Enabled '$Name'."  -Level "success" } catch { Write-Log "Failed to enable '$Name': $($_.Exception.Message)" -Level "fail" } }
if ($disable) { try { Disable-LocalUser -Name $Name -ErrorAction Stop; Write-Log "Disabled '$Name'." -Level "success" } catch { Write-Log "Failed to disable '$Name': $($_.Exception.Message)" -Level "fail" } }

if ($null -ne $comment) {
    try { & net.exe user $Name /comment:"$comment" 2>&1 | Out-Null; Write-Log "Set comment for '$Name'." -Level "success" }
    catch { Write-Log "Failed to set comment for '$Name': $($_.Exception.Message)" -Level "warn" }
}

if ($promote) { $addGroups += "Administrators" }
if ($demote)  { $removeGroups += "Administrators" }

foreach ($g in ($addGroups | Where-Object { $_ })) {
    try { Add-LocalGroupMember -Group $g -Member $Name -ErrorAction Stop; Write-Log "Added '$Name' to '$g'." -Level "success" }
    catch {
        if ($_.Exception.Message -match "already a member") { Write-Log "'$Name' already in '$g'." -Level "info" }
        else { Write-Log "Failed to add '$Name' to '$g': $($_.Exception.Message)" -Level "warn" }
    }
}
foreach ($g in ($removeGroups | Where-Object { $_ })) {
    try { Remove-LocalGroupMember -Group $g -Member $Name -ErrorAction Stop; Write-Log "Removed '$Name' from '$g'." -Level "success" }
    catch { Write-Log "Failed to remove '$Name' from '$g': $($_.Exception.Message)" -Level "warn" }
}

if ($newName) {
    try { Rename-LocalUser -Name $Name -NewName $newName -ErrorAction Stop; Write-Log "Renamed '$Name' -> '$newName'." -Level "success" }
    catch { Write-Log "Failed to rename '$Name' -> '$newName': $($_.Exception.Message)" -Level "fail" }
}

Save-LogFile -Status "ok"
exit 0
