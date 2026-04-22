# --------------------------------------------------------------------------
#  Helper: Install WhatsApp Desktop via Chocolatey
#  Skips Microsoft Store -- per user decision (locked in 2025-batch spec).
# --------------------------------------------------------------------------

# -- Bootstrap shared helpers (idempotent) ------------------------------------
$_sharedDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "shared"
$_loggingPath = Join-Path $_sharedDir "logging.ps1"
if ((Test-Path $_loggingPath) -and -not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    . $_loggingPath
}
$_chocoUtilsPath = Join-Path $_sharedDir "choco-utils.ps1"
if ((Test-Path $_chocoUtilsPath) -and -not (Get-Command Install-ChocoPackage -ErrorAction SilentlyContinue)) {
    . $_chocoUtilsPath
}

function Get-WhatsAppPath {
    <#
    .SYNOPSIS
        Searches for WhatsApp.exe in common install locations.
        Returns the path string or $null.
    #>
    $candidates = @(
        "$env:LOCALAPPDATA\WhatsApp\WhatsApp.exe",
        "$env:LOCALAPPDATA\Programs\WhatsApp\WhatsApp.exe",
        "$env:ProgramFiles\WhatsApp\WhatsApp.exe",
        "${env:ProgramFiles(x86)}\WhatsApp\WhatsApp.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Invoke-WhatsAppOfficialInstaller {
    <#
    .SYNOPSIS
        Downloads the official WhatsAppSetup.exe and runs it silently.
        Returns @{ ok = $bool; path = "<path or null>"; reason = "<text>" }.
    #>
    param(
        [Parameter(Mandatory)] $Fallback,
        [Parameter(Mandatory)] $LogMessages,
        [Parameter(Mandatory)] [string]$TriggerReason
    )

    $msgs = $LogMessages.messages

    $isFallbackDisabled = -not $Fallback.enabled
    if ($isFallbackDisabled) {
        Write-Log $msgs.fallbackDisabled -Level "error"
        return @{ ok = $false; path = $null; reason = "fallback disabled" }
    }

    $url = [string]$Fallback.url
    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-FileError -FilePath "config.json" -Operation "read" -Reason "fallback.url is empty -- cannot download official installer" -Module "Install-WhatsApp"
        return @{ ok = $false; path = $null; reason = "missing fallback.url" }
    }

    $fileName = [string]$Fallback.fileName
    if ([string]::IsNullOrWhiteSpace($fileName)) { $fileName = "WhatsAppSetup.exe" }

    $downloadDir = [string]$Fallback.downloadDir
    if ([string]::IsNullOrWhiteSpace($downloadDir)) { $downloadDir = $env:TEMP }
    if ([string]::IsNullOrWhiteSpace($downloadDir)) { $downloadDir = [System.IO.Path]::GetTempPath() }

    $hasDownloadDir = Test-Path -LiteralPath $downloadDir
    if (-not $hasDownloadDir) {
        try {
            New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
        } catch {
            Write-FileError -FilePath $downloadDir -Operation "mkdir" -Reason "cannot create download dir for fallback installer: $($_.Exception.Message)" -Module "Install-WhatsApp"
            return @{ ok = $false; path = $null; reason = "mkdir failed" }
        }
    }

    $dest = Join-Path $downloadDir $fileName

    Write-Log ($msgs.fallbackTriggered -replace '\{reason\}', $TriggerReason) -Level "warn"
    Write-Log (($msgs.fallbackDownloading -replace '\{url\}', $url) -replace '\{dest\}', $dest) -Level "info"

    # -- Download ---------------------------------------------------------
    try {
        $previousProgress = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        } catch { }
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        $ProgressPreference = $previousProgress
    } catch {
        Write-FileError -FilePath $dest -Operation "download" -Reason "Invoke-WebRequest from $url failed: $($_.Exception.Message)" -Module "Install-WhatsApp"
        Write-Log (($msgs.fallbackDownloadFailed -replace '\{url\}', $url) -replace '\{error\}', $_.Exception.Message) -Level "error"
        return @{ ok = $false; path = $null; reason = "download failed" }
    }

    $hasFile = Test-Path -LiteralPath $dest
    if (-not $hasFile) {
        Write-FileError -FilePath $dest -Operation "verify" -Reason "downloaded installer not found on disk after Invoke-WebRequest" -Module "Install-WhatsApp"
        return @{ ok = $false; path = $null; reason = "downloaded file missing" }
    }

    $fileBytes = 0
    try { $fileBytes = (Get-Item -LiteralPath $dest).Length } catch { }
    $isTooSmall = $fileBytes -lt 1MB
    if ($isTooSmall) {
        Write-FileError -FilePath $dest -Operation "verify" -Reason "downloaded installer is suspiciously small ($fileBytes bytes) -- aborting before execution" -Module "Install-WhatsApp"
        return @{ ok = $false; path = $null; reason = "installer too small ($fileBytes bytes)" }
    }
    Write-Log (($msgs.fallbackDownloadOk -replace '\{bytes\}', $fileBytes) -replace '\{dest\}', $dest) -Level "success"

    # -- Run silently ------------------------------------------------------
    $silentArgs = [string]$Fallback.silentArgs
    if ([string]::IsNullOrWhiteSpace($silentArgs)) { $silentArgs = "/S" }

    $timeout = [int]$Fallback.timeoutSeconds
    if ($timeout -le 0) { $timeout = 600 }

    Write-Log (($msgs.fallbackRunning -replace '\{path\}', $dest) -replace '\{args\}', $silentArgs) -Level "info"

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $proc = Start-Process -FilePath $dest -ArgumentList $silentArgs -PassThru -WindowStyle Hidden -ErrorAction Stop
        $hasExited = $proc.WaitForExit($timeout * 1000)
        if (-not $hasExited) {
            try { $proc.Kill() } catch { }
            Write-Log "Official installer timed out after ${timeout}s -- killed" -Level "error"
            return @{ ok = $false; path = $null; reason = "installer timeout" }
        }
        $sw.Stop()
        $exitCode = $proc.ExitCode
        Write-Log (($msgs.fallbackInstallerExited -replace '\{code\}', $exitCode) -replace '\{seconds\}', [int]$sw.Elapsed.TotalSeconds) -Level "info"
        $isExitOk = $exitCode -eq 0
        if (-not $isExitOk) {
            Write-Log ($msgs.fallbackInstallerFailed -replace '\{error\}', "non-zero exit code $exitCode") -Level "error"
            return @{ ok = $false; path = $null; reason = "exit $exitCode" }
        }
    } catch {
        Write-Log ($msgs.fallbackInstallerFailed -replace '\{error\}', $_.Exception.Message) -Level "error"
        return @{ ok = $false; path = $null; reason = "start-process failed" }
    }

    # -- Verify ------------------------------------------------------------
    $installedPath = Get-WhatsAppPath
    if (-not $installedPath) {
        Write-FileError -FilePath $dest -Operation "verify" -Reason "official installer ran (exit 0) but WhatsApp.exe not found in any expected location" -Module "Install-WhatsApp"
        Write-Log $msgs.fallbackVerifyFailed -Level "error"
        return @{ ok = $false; path = $null; reason = "post-install verify failed" }
    }

    Write-Log ($msgs.fallbackSuccess -replace '\{path\}', $installedPath) -Level "success"
    return @{ ok = $true; path = $installedPath; reason = "ok" }
}

function Install-WhatsApp {
    <#
    .SYNOPSIS
        Installs WhatsApp Desktop via Chocolatey, with fallback to the official
        WhatsAppSetup.exe download when Chocolatey fails or verification fails.
        Returns $true on success.
    #>
    param(
        [Parameter(Mandatory)] $WaConfig,
        [Parameter(Mandatory)] $LogMessages
    )

    $msgs = $LogMessages.messages

    $isDisabled = -not $WaConfig.enabled
    if ($isDisabled) {
        Write-Log "WhatsApp install disabled in config -- skipping" -Level "info"
        return $true
    }

    Write-Log $msgs.checking -Level "info"

    $existing = Get-WhatsAppPath
    if ($existing) {
        $version = "unknown"
        try { $version = (Get-Item $existing).VersionInfo.ProductVersion } catch { }
        $isAlreadyInstalled = Test-AlreadyInstalled -Name "whatsapp" -CurrentVersion $version
        if ($isAlreadyInstalled) {
            Write-Log ($msgs.alreadyInstalled -replace '\{path\}', $existing) -Level "success"
            return $true
        }
        Write-Log "WhatsApp.exe found at $existing but no tracking record -- recording" -Level "info"
        Save-InstalledRecord -Name "whatsapp" -Version $version -Method "chocolatey"
        return $true
    }

    Write-Log $msgs.notFound -Level "info"
    Write-Log $msgs.installing -Level "info"

    $hasFallbackConfig = $null -ne $WaConfig.PSObject.Properties['fallback']
    $fallback = if ($hasFallbackConfig) { $WaConfig.fallback } else { $null }

    $isInstalled = Install-ChocoPackage -PackageName $WaConfig.chocoPackage
    if (-not $isInstalled) {
        Write-Log ($msgs.installFailed -replace '\{error\}', "choco install whatsapp returned failure") -Level "warn"
        if ($null -eq $fallback) {
            Save-InstalledError -Name "whatsapp" -ErrorMessage "choco install whatsapp failed and no fallback configured"
            return $false
        }
        $result = Invoke-WhatsAppOfficialInstaller -Fallback $fallback -LogMessages $LogMessages -TriggerReason "choco install returned failure"
        if (-not $result.ok) {
            Save-InstalledError -Name "whatsapp" -ErrorMessage "choco failed; fallback failed: $($result.reason)"
            return $false
        }
        $version = "unknown"
        try { $version = (Get-Item $result.path).VersionInfo.ProductVersion } catch { }
        Save-InstalledRecord -Name "whatsapp" -Version $version -Method "official-installer"
        return $true
    }

    # -- Verify Chocolatey install ---------------------------------------------
    $installedPath = Get-WhatsAppPath
    if (-not $installedPath) {
        $checked = @(
            "$env:LOCALAPPDATA\WhatsApp\WhatsApp.exe",
            "$env:LOCALAPPDATA\Programs\WhatsApp\WhatsApp.exe",
            "$env:ProgramFiles\WhatsApp\WhatsApp.exe",
            "${env:ProgramFiles(x86)}\WhatsApp\WhatsApp.exe"
        ) -join ", "
        Write-FileError -FilePath $checked -Operation "verify" -Reason "WhatsApp.exe not found after choco install -- checked: $checked" -Module "Install-WhatsApp"
        Write-Log $msgs.verifyFailed -Level "warn"

        if ($null -eq $fallback) {
            Save-InstalledError -Name "whatsapp" -ErrorMessage "Verify failed: WhatsApp.exe not in expected locations after install"
            return $false
        }
        $result = Invoke-WhatsAppOfficialInstaller -Fallback $fallback -LogMessages $LogMessages -TriggerReason "choco install verify failed"
        if (-not $result.ok) {
            Save-InstalledError -Name "whatsapp" -ErrorMessage "choco verify failed; fallback failed: $($result.reason)"
            return $false
        }
        $version = "unknown"
        try { $version = (Get-Item $result.path).VersionInfo.ProductVersion } catch { }
        Save-InstalledRecord -Name "whatsapp" -Version $version -Method "official-installer"
        return $true
    }

    $version = "unknown"
    try { $version = (Get-Item $installedPath).VersionInfo.ProductVersion } catch { }

    Write-Log ($msgs.installSuccess -replace '\{path\}', $installedPath) -Level "success"
    Save-InstalledRecord -Name "whatsapp" -Version $version -Method "chocolatey"
    return $true
}

function Expand-WaPath {
    <#
    .SYNOPSIS
        Expands %ENV% tokens in a path string. Returns $null on failure.
    #>
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }
    try { return [Environment]::ExpandEnvironmentVariables($Raw) } catch { return $Raw }
}

function Remove-WaRegistryKeys {
    <#
    .SYNOPSIS
        Removes a list of registry keys (HKCU/HKLM). Returns a hashtable counter
        @{ removed = N; missing = N; failed = N }.
    #>
    param(
        [Parameter(Mandatory)] [string[]]$Keys,
        [Parameter(Mandatory)] $LogMessages
    )
    $msgs = $LogMessages.messages
    $counter = @{ removed = 0; missing = 0; failed = 0 }

    foreach ($key in $Keys) {
        if ([string]::IsNullOrWhiteSpace($key)) { continue }
        $hasKey = Test-Path -LiteralPath $key -ErrorAction SilentlyContinue
        if (-not $hasKey) {
            Write-Log ($msgs.cleanupRegKeyMissing -replace '\{path\}', $key) -Level "info"
            $counter.missing++
            continue
        }
        try {
            Remove-Item -LiteralPath $key -Recurse -Force -ErrorAction Stop
            Write-Log ($msgs.cleanupRegKeyRemoved -replace '\{path\}', $key) -Level "success"
            $counter.removed++
        } catch {
            Write-FileError -FilePath $key -Operation "registry delete" -Reason "Remove-Item failed: $($_.Exception.Message)" -Module "Uninstall-WhatsApp"
            Write-Log (($msgs.cleanupRegKeyFailed -replace '\{path\}', $key) -replace '\{error\}', $_.Exception.Message) -Level "error"
            $counter.failed++
        }
    }
    return $counter
}

function Remove-WaShortcuts {
    <#
    .SYNOPSIS
        Removes shortcut .lnk files and Start-Menu folders. Returns
        @{ removed = N; missing = N; failed = N }.
    #>
    param(
        [Parameter(Mandatory)] [string[]]$Paths,
        [Parameter(Mandatory)] $LogMessages
    )
    $msgs = $LogMessages.messages
    $counter = @{ removed = 0; missing = 0; failed = 0 }

    foreach ($raw in $Paths) {
        $p = Expand-WaPath -Raw $raw
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $hasPath = Test-Path -LiteralPath $p -ErrorAction SilentlyContinue
        if (-not $hasPath) {
            Write-Log ($msgs.cleanupShortcutMissing -replace '\{path\}', $p) -Level "info"
            $counter.missing++
            continue
        }
        try {
            $item = Get-Item -LiteralPath $p -Force -ErrorAction Stop
            $isContainer = $item.PSIsContainer
            if ($isContainer) {
                Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop
            } else {
                Remove-Item -LiteralPath $p -Force -ErrorAction Stop
            }
            Write-Log ($msgs.cleanupShortcutRemoved -replace '\{path\}', $p) -Level "success"
            $counter.removed++
        } catch {
            Write-FileError -FilePath $p -Operation "shortcut delete" -Reason "Remove-Item failed: $($_.Exception.Message)" -Module "Uninstall-WhatsApp"
            Write-Log (($msgs.cleanupShortcutFailed -replace '\{path\}', $p) -replace '\{error\}', $_.Exception.Message) -Level "error"
            $counter.failed++
        }
    }
    return $counter
}

function Invoke-WaPostUninstallCleanup {
    <#
    .SYNOPSIS
        Removes leftover WhatsApp registry keys, Start Menu / Desktop / Taskbar
        shortcuts, and (optionally) the LOCALAPPDATA install dir after the
        Chocolatey uninstall step has run.
    #>
    param(
        [Parameter(Mandatory)] $WaConfig,
        [Parameter(Mandatory)] $LogMessages
    )
    $msgs = $LogMessages.messages

    $hasCleanupConfig = $null -ne $WaConfig.PSObject.Properties['uninstallCleanup']
    if (-not $hasCleanupConfig) {
        Write-Log "uninstallCleanup block missing from config -- skipping sweep" -Level "warn"
        return
    }
    $cleanup = $WaConfig.uninstallCleanup

    $isCleanupDisabled = -not $cleanup.enabled
    if ($isCleanupDisabled) {
        Write-Log $msgs.cleanupSkipped -Level "info"
        return
    }

    Write-Log $msgs.cleanupStart -Level "info"

    $regCounter = @{ removed = 0; missing = 0; failed = 0 }
    $isRegEnabled = $cleanup.removeRegistryKeys
    if ($isRegEnabled) {
        $regCounter = Remove-WaRegistryKeys -Keys $cleanup.registryKeys -LogMessages $LogMessages
    }

    $scCounter = @{ removed = 0; missing = 0; failed = 0 }
    $isShortcutEnabled = $cleanup.removeShortcuts
    if ($isShortcutEnabled) {
        $scCounter = Remove-WaShortcuts -Paths $cleanup.shortcutPaths -LogMessages $LogMessages
    }

    # -- AppData folder (opt-in only) --------------------------------------
    $hasAppDataList = $null -ne $cleanup.PSObject.Properties['appDataPaths'] -and $cleanup.appDataPaths
    if ($hasAppDataList) {
        $isPurge = $cleanup.purgeAppData
        foreach ($raw in $cleanup.appDataPaths) {
            $p = Expand-WaPath -Raw $raw
            if ([string]::IsNullOrWhiteSpace($p)) { continue }
            $hasFolder = Test-Path -LiteralPath $p -ErrorAction SilentlyContinue
            if (-not $hasFolder) { continue }
            if (-not $isPurge) {
                Write-Log ($msgs.cleanupAppDataKept -replace '\{path\}', $p) -Level "info"
                continue
            }
            try {
                Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop
                Write-Log ($msgs.cleanupAppDataPurged -replace '\{path\}', $p) -Level "success"
            } catch {
                Write-FileError -FilePath $p -Operation "appdata delete" -Reason "Remove-Item failed: $($_.Exception.Message)" -Module "Uninstall-WhatsApp"
            }
        }
    }

    $summary = $msgs.cleanupSummary
    $summary = $summary -replace '\{regRemoved\}', $regCounter.removed
    $summary = $summary -replace '\{regMissing\}', $regCounter.missing
    $summary = $summary -replace '\{regFailed\}', $regCounter.failed
    $summary = $summary -replace '\{scRemoved\}', $scCounter.removed
    $summary = $summary -replace '\{scMissing\}', $scCounter.missing
    $summary = $summary -replace '\{scFailed\}', $scCounter.failed
    $hasAnyFailure = ($regCounter.failed + $scCounter.failed) -gt 0
    Write-Log $summary -Level $(if ($hasAnyFailure) { "warn" } else { "success" })
}

function Uninstall-WhatsApp {
    param($WaConfig, $LogMessages)

    Write-Log ($LogMessages.messages.uninstalling -replace '\{name\}', "WhatsApp") -Level "info"
    $isUninstalled = Uninstall-ChocoPackage -PackageName $WaConfig.chocoPackage
    if ($isUninstalled) {
        Write-Log ($LogMessages.messages.uninstallSuccess -replace '\{name\}', "WhatsApp") -Level "success"
    } else {
        Write-Log ($LogMessages.messages.uninstallFailed -replace '\{name\}', "WhatsApp") -Level "warn"
    }

    # -- Sweep leftover registry keys + shortcuts ------------------------------
    Invoke-WaPostUninstallCleanup -WaConfig $WaConfig -LogMessages $LogMessages

    Remove-InstalledRecord -Name "whatsapp"
    Remove-ResolvedData -ScriptFolder "49-install-whatsapp"

    Write-Log $LogMessages.messages.uninstallComplete -Level "success"
}
