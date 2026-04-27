<#
.SYNOPSIS
    Cross-script helpers to detect which VS Code editions (Stable / Insiders)
    are currently installed on this machine and to return the matching
    registry keys + Code executable paths for each.

.DESCRIPTION
    Detection probes the well-known per-user and per-machine install folders
    for both editions. For every edition that is detected, the helper also
    expands the per-edition registry paths and the resolved Code.exe path
    using the same config schema script 52 already uses
    (config.editions.<name>.{vscodePath, registryPaths, contextMenuLabel}).

    Callers can use:
      - Test-VsCodeEditionInstalled  -> [bool] for a single edition
      - Get-InstalledVsCodeEditions  -> string[] of installed edition names,
                                        filtered against config.enabledEditions
      - Resolve-VsCodeEditionContext -> hashtable per edition with the
                                        correct registry keys + exe path

    CODE RED: every file/path failure includes the full path + reason.
#>

Set-StrictMode -Version Latest

function Test-VsCodeEditionInstalled {
    <#
    .SYNOPSIS  Returns $true iff Code.exe / Code - Insiders.exe exists in one
               of the well-known per-user or per-machine install folders.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('stable','insiders')]
        [string]$EditionName
    )

    $isInsiders = ($EditionName -eq 'insiders')
    $exeName    = if ($isInsiders) { 'Code - Insiders.exe' }            else { 'Code.exe' }
    $folderName = if ($isInsiders) { 'Microsoft VS Code Insiders' }     else { 'Microsoft VS Code' }

    $candidates = New-Object System.Collections.Generic.List[string]

    # Per-user install (squirrel)  : %LOCALAPPDATA%\Programs\<folder>\<exe>
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $candidates.Add((Join-Path $env:LOCALAPPDATA  ("Programs\$folderName\$exeName")))
    }
    # Per-machine install (system) : %ProgramFiles%\<folder>\<exe>
    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $candidates.Add((Join-Path $env:ProgramFiles  ("$folderName\$exeName")))
    }
    # 32-bit per-machine fallback  : %ProgramFiles(x86)%\<folder>\<exe>
    $pf86 = ${env:ProgramFiles(x86)}
    if (-not [string]::IsNullOrWhiteSpace($pf86)) {
        $candidates.Add((Join-Path $pf86 ("$folderName\$exeName")))
    }
    # Chocolatey shim
    if (-not [string]::IsNullOrWhiteSpace($env:ProgramData)) {
        $candidates.Add((Join-Path $env:ProgramData ("chocolatey\bin\$exeName")))
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $true }
    }
    return $false
}

function Get-InstalledVsCodeEditions {
    <#
    .SYNOPSIS  Returns the subset of $EnabledEditions that are actually
               installed on this machine (preserves caller order).

    .PARAMETER EnabledEditions
        The enabledEditions array from the script's config.json.

    .PARAMETER LogMsgs
        Optional log-messages object so detection lines route through Write-Log.
        Falls back to plain Write-Host when omitted or when Write-Log isn't
        loaded (e.g. tiny inline scripts like manual-repair.ps1).
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$EnabledEditions,

        [PSObject]$LogMsgs = $null
    )

    $result = New-Object System.Collections.Generic.List[string]
    foreach ($name in $EnabledEditions) {
        $isKnown = ($name -in @('stable','insiders'))
        if (-not $isKnown) {
            $msg = "[edition-detect] skipping unknown edition '$name' (allowed: stable, insiders)"
            if ($LogMsgs -and (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
                Write-Log $msg -Level "warn"
            } else {
                Write-Host $msg -ForegroundColor Yellow
            }
            continue
        }

        $isInstalled = Test-VsCodeEditionInstalled -EditionName $name
        $line = "[edition-detect] '{0}' installed = {1}" -f $name, $isInstalled
        if ($LogMsgs -and (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
            Write-Log $line -Level $(if ($isInstalled) { "success" } else { "warn" })
        } else {
            $colour = if ($isInstalled) { 'Green' } else { 'DarkYellow' }
            Write-Host $line -ForegroundColor $colour
        }
        if ($isInstalled) { $result.Add($name) }
    }
    return ,@($result)
}

function Resolve-VsCodeEditionContext {
    <#
    .SYNOPSIS  For each installed + enabled edition returns a hashtable with:
                 name, label, registryPaths (per-target, expanded),
                 vscodePath (raw), resolvedExe (Test-Path verified or $null).

    .DESCRIPTION
        This is the single place that maps an *installed edition name*
        to the *correct* registry keys and Code.exe path. Callers should
        iterate the returned array and apply per-edition operations directly
        (no edition-specific branching needed).

    .PARAMETER Config
        The full config.json object (must contain .editions.<name>).

    .PARAMETER InstallationType
        'user' or 'system' -- passed through to Resolve-VsCodePath.

    .PARAMETER ScriptDir
        Script root (used by Resolve-VsCodePath for the .resolved cache).

    .PARAMETER LogMsgs
        log-messages.json object (optional; used for routed logging).

    .PARAMETER OnlyInstalled
        When $true (default), filters to editions that are actually installed.
        Set to $false to return contexts for every enabled edition (e.g. for
        verify / dry-run that wants to report missing installs).
    #>
    param(
        [Parameter(Mandatory)] [PSObject] $Config,
        [Parameter(Mandatory)] [string]   $InstallationType,
        [Parameter(Mandatory)] [string]   $ScriptDir,
        [PSObject] $LogMsgs = $null,
        [bool]     $OnlyInstalled = $true
    )

    $enabled = @($Config.enabledEditions)
    $names   = if ($OnlyInstalled) {
        Get-InstalledVsCodeEditions -EnabledEditions $enabled -LogMsgs $LogMsgs
    } else {
        $enabled
    }

    $contexts = New-Object System.Collections.Generic.List[hashtable]
    foreach ($name in $names) {
        $editionCfg = $Config.editions.$name
        if ($null -eq $editionCfg) {
            $msg = "[edition-detect] config.editions.$name is missing in config.json"
            if ($LogMsgs -and (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
                Write-Log $msg -Level "error"
            } else {
                Write-Host $msg -ForegroundColor Red
            }
            continue
        }

        $resolvedExe = $null
        if (Get-Command Resolve-VsCodePath -ErrorAction SilentlyContinue) {
            try {
                $resolvedExe = Resolve-VsCodePath `
                    -PathConfig    $editionCfg.vscodePath `
                    -PreferredType $InstallationType `
                    -ScriptDir     $ScriptDir `
                    -EditionName   $name
            } catch {
                $msg = "[edition-detect] Resolve-VsCodePath failed for edition '$name' (script dir: $ScriptDir) -- reason: $_"
                if ($LogMsgs -and (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
                    Write-Log $msg -Level "error"
                } else {
                    Write-Host $msg -ForegroundColor Red
                }
            }
        }

        $contexts.Add(@{
            name          = $name
            label         = $editionCfg.contextMenuLabel
            registryPaths = $editionCfg.registryPaths
            vscodePath    = $editionCfg.vscodePath
            resolvedExe   = $resolvedExe
            isInstalled   = (Test-VsCodeEditionInstalled -EditionName $name)
        })
    }

    return ,@($contexts)
}
