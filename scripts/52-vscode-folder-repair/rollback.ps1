# --------------------------------------------------------------------------
#  Script 52 -- rollback.ps1
#
#  Restores the DEFAULT VS Code context menu entries on ALL THREE targets:
#      *  (file)        -> HKCR\*\shell\VSCode[Insiders]
#         directory     -> HKCR\Directory\shell\VSCode[Insiders]
#         background    -> HKCR\Directory\Background\shell\VSCode[Insiders]
#
#  This is the INVERSE of run.ps1 (which narrows the menu to folders only).
#  Use it to undo the folder-only repair and put the menu back to the
#  classic state created by the official VS Code installer.
#
#  Behavior summary:
#    * Reuses config.json from script 52 (registry paths + label).
#    * Pulls command templates from editions.<name>.defaultCommandTemplates.
#    * Resolves Code.exe via the same Resolve-VsCodePath helper run.ps1 uses,
#      so user vs. system installs are handled identically.
#    * Writes parent key (Default + Icon) and \command subkey for each target.
#    * Verifies all three are present afterwards.
#    * Restarts explorer.exe (unless invoked with "no-restart") so the menu
#      refreshes immediately.
#    * On any failure, logs the EXACT registry path + reason (CODE RED rule).
# --------------------------------------------------------------------------
param(
    [Parameter(Position = 0)]
    [string]$Command = "all",

    [string]$Edition,
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sharedDir = Join-Path (Split-Path -Parent $scriptDir) "shared"

# -- Dot-source shared helpers ------------------------------------------------
. (Join-Path $sharedDir "logging.ps1")
. (Join-Path $sharedDir "resolved.ps1")
. (Join-Path $sharedDir "help.ps1")

# -- Dot-source script helpers (Restart-Explorer + ConvertTo-RegPath etc.) ---
. (Join-Path $scriptDir "helpers\repair.ps1")

# -- Load config & log messages -----------------------------------------------
$configPath = Join-Path $scriptDir "config.json"
$isConfigMissing = -not (Test-Path -LiteralPath $configPath)
if ($isConfigMissing) {
    Write-Host "FATAL: config.json not found at $configPath" -ForegroundColor Red
    exit 1
}
$config      = Import-JsonConfig $configPath
$logMessages = Import-JsonConfig (Join-Path $scriptDir "log-messages.json")

# -- Help ---------------------------------------------------------------------
if ($Help -or $Command -eq "--help") {
    Show-ScriptHelp -LogMessages $logMessages
    return
}

# -- Banner -------------------------------------------------------------------
Write-Banner -Title $logMessages.messages.rollbackBanner

# -- Initialize logging -------------------------------------------------------
Initialize-Logging -ScriptName ($logMessages.scriptName + " -- rollback")

# -- Local helper: write one default entry ------------------------------------
function Restore-DefaultMenuEntry {
    <#
    .SYNOPSIS
        Writes parent key (Default + Icon) and \command subkey for one target,
        using the default command template from config.json.
    #>
    param(
        [string]$TargetName,
        [string]$RegistryPath,
        [string]$Label,
        [string]$VsCodeExe,
        [string]$CommandTemplate,
        [PSObject]$LogMsgs
    )

    $regPath  = ConvertTo-RegPath $RegistryPath
    $cmdLine  = $CommandTemplate -replace '\{exe\}', $VsCodeExe
    $iconVal  = "`"$VsCodeExe`""

    Write-Log (($LogMsgs.messages.rollbackTargetWriting -replace '\{target\}', $TargetName) -replace '\{path\}', $regPath) -Level "info"
    Write-Log ($LogMsgs.messages.rollbackTargetWriteCmd -replace '\{command\}', $cmdLine) -Level "info"

    try {
        $subKeyPath = $RegistryPath -replace '^Registry::HKEY_CLASSES_ROOT\\', ''
        $hkcr = [Microsoft.Win32.Registry]::ClassesRoot

        $key = $hkcr.CreateSubKey($subKeyPath)
        $key.SetValue("",     $Label)
        $key.SetValue("Icon", $iconVal)
        $key.Close()

        $cmdKey = $hkcr.CreateSubKey("$subKeyPath\command")
        $cmdKey.SetValue("", $cmdLine)
        $cmdKey.Close()

        $msg = ($LogMsgs.messages.rollbackTargetOk -replace '\{target\}', $TargetName) `
                                                   -replace '\{label\}',  $Label `
                                                   -replace '\{path\}',   $regPath
        Write-Log $msg -Level "success"
        return $true
    } catch {
        $msg = ($LogMsgs.messages.rollbackTargetFailed -replace '\{target\}', $TargetName) `
                                                       -replace '\{path\}',   $regPath `
                                                       -replace '\{error\}',  $_
        Write-Log $msg -Level "error"
        return $false
    }
}

try {

    # -- Disabled check -------------------------------------------------------
    $isDisabled = -not $config.enabled
    if ($isDisabled) {
        Write-Log $logMessages.messages.scriptDisabled -Level "warn"
        return
    }

    # -- Assert admin ---------------------------------------------------------
    Write-Log $logMessages.messages.checkingAdmin -Level "info"
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $hasAdminRights = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Log ($logMessages.messages.currentUser -replace '\{name\}', $identity.Name) -Level "info"
    Write-Log ($logMessages.messages.isAdministrator -replace '\{value\}', $hasAdminRights) -Level $(if ($hasAdminRights) { "success" } else { "error" })

    $isNotAdmin = -not $hasAdminRights
    if ($isNotAdmin) {
        Write-Log $logMessages.messages.notAdmin -Level "error"
        return
    }

    Write-Log $logMessages.messages.rollbackStart -Level "info"

    # -- Decide editions ------------------------------------------------------
    $hasEditionFilter = -not [string]::IsNullOrWhiteSpace($Edition)
    $editions = if ($hasEditionFilter) { @($Edition) } else { @($config.enabledEditions) }
    $installType = $config.installationType

    Write-Log ($logMessages.messages.installTypePref -replace '\{type\}', $installType) -Level "info"
    Write-Log ($logMessages.messages.enabledEditions -replace '\{editions\}', ($editions -join ', ')) -Level "info"

    $isAllSuccessful = $true

    foreach ($editionName in $editions) {
        $edition = $config.editions.$editionName
        $isEditionMissing = $null -eq $edition
        if ($isEditionMissing) {
            Write-Log ($logMessages.messages.unknownEdition -replace '\{name\}', $editionName) -Level "warn"
            $isAllSuccessful = $false
            continue
        }

        Write-Host ""
        Write-Host $logMessages.messages.editionBorderLine -ForegroundColor DarkCyan
        Write-Host ($logMessages.messages.editionLabel -replace '\{label\}', $edition.contextMenuLabel) -ForegroundColor Cyan
        Write-Host $logMessages.messages.editionBorderLine -ForegroundColor DarkCyan

        # Resolve VS Code exe (required for all three writes)
        Write-Log $logMessages.messages.detectInstall -Level "info"
        $vsCodeExe = Resolve-VsCodePath `
            -PathConfig    $edition.vscodePath `
            -PreferredType $installType `
            -ScriptDir     $scriptDir `
            -EditionName   $editionName

        $isExeMissing = -not $vsCodeExe
        if ($isExeMissing) {
            Write-Log ($logMessages.messages.rollbackExeMissing -replace '\{edition\}', $editionName) -Level "error"
            $isAllSuccessful = $false
            continue
        }
        Write-Log ($logMessages.messages.usingExe -replace '\{path\}', $vsCodeExe) -Level "success"

        $hasTemplates = ($edition.PSObject.Properties.Name -contains 'defaultCommandTemplates') -and $edition.defaultCommandTemplates
        if (-not $hasTemplates) {
            Write-Log ("No defaultCommandTemplates block for edition '$editionName' in config.json -- cannot restore.") -Level "error"
            $isAllSuccessful = $false
            continue
        }

        # 1. Restore each of the three targets ------------------------------
        foreach ($target in @('file', 'directory', 'background')) {
            $regPath = $edition.registryPaths.$target
            $hasRegPath = -not [string]::IsNullOrWhiteSpace($regPath)
            if (-not $hasRegPath) {
                Write-Log ("No registryPaths.$target for edition '$editionName' -- skipping.") -Level "warn"
                continue
            }

            $cmdTemplate = $edition.defaultCommandTemplates.$target
            $hasTemplate = -not [string]::IsNullOrWhiteSpace($cmdTemplate)
            if (-not $hasTemplate) {
                $msg = ($logMessages.messages.rollbackMissingTemplate -replace '\{target\}', $target) -replace '\{edition\}', $editionName
                Write-Log $msg -Level "warn"
                $isAllSuccessful = $false
                continue
            }

            $ok = Restore-DefaultMenuEntry `
                -TargetName      $target `
                -RegistryPath    $regPath `
                -Label           $edition.contextMenuLabel `
                -VsCodeExe       $vsCodeExe `
                -CommandTemplate $cmdTemplate `
                -LogMsgs         $logMessages
            if (-not $ok) { $isAllSuccessful = $false }
        }

        # 2. Verify all three are present -----------------------------------
        Write-Log $logMessages.messages.rollbackVerify -Level "info"
        foreach ($target in @('file', 'directory', 'background')) {
            $regPath = $edition.registryPaths.$target
            if ([string]::IsNullOrWhiteSpace($regPath)) { continue }
            $ok = Test-TargetState -TargetName $target -RegistryPath $regPath -Expected "present" -LogMsgs $logMessages
            if (-not $ok) { $isAllSuccessful = $false }
        }
    }

    # -- Restart Explorer -----------------------------------------------------
    $isNoRestartCommand = $Command.ToLower() -eq "no-restart"
    $shouldRestart      = $config.restartExplorer -and -not $isNoRestartCommand
    if ($shouldRestart) {
        $hasWaitProp = $config.PSObject.Properties.Match('restartExplorerWaitMs').Count -gt 0
        $waitMs = if ($hasWaitProp) { [int]$config.restartExplorerWaitMs } else { 800 }
        $null = Restart-Explorer -WaitMs $waitMs -LogMsgs $logMessages
    } else {
        Write-Log $logMessages.messages.explorerSkipped -Level "info"
    }

    # -- Summary --------------------------------------------------------------
    if ($isAllSuccessful) {
        Write-Log $logMessages.messages.rollbackDone -Level "success"
    } else {
        Write-Log $logMessages.messages.rollbackPartial -Level "warn"
    }

    # -- Save resolved state --------------------------------------------------
    Save-ResolvedData -ScriptFolder "52-vscode-folder-repair" -Data @{
        action          = "rollback"
        editions        = ($editions -join ',')
        restoredTargets = "file,directory,background"
        restartExplorer = [bool]$shouldRestart
        timestamp       = (Get-Date -Format "o")
    }

} catch {
    Write-Log "Unhandled error: $_" -Level "error"
    Write-Log "Stack: $($_.ScriptStackTrace)" -Level "error"
} finally {
    $hasAnyErrors = $script:_LogErrors.Count -gt 0
    Save-LogFile -Status $(if ($hasAnyErrors) { "fail" } else { "ok" })
}
