# --------------------------------------------------------------------------
#  Script 53 -- tests/run-tests.ps1
#
#  Plain PowerShell test harness for the Script Fixer context-menu install.
#  Executes the registry assertions described in spec/53-.../readme.md
#  section 17 (cases 6 - 13) against a LIVE installation, prints a colored
#  pass/fail summary, and exits 0 (all green) or 1 (any failure).
#
#  Usage:
#    .\run-tests.ps1                                # default: script 52, EditorsAndIdes, file scope
#    .\run-tests.ps1 -ScriptId 10 -Category Editors -LeafName "10-install-vscode"
#    .\run-tests.ps1 -Scope Directory               # test the folder context menu instead
#    .\run-tests.ps1 -OnlyCases 6,8,12              # run a subset
#    .\run-tests.ps1 -Verbose                       # print every assertion
#
#  Requires: an admin shell on a Windows machine where script 53 is installed.
# --------------------------------------------------------------------------
[CmdletBinding()]
param(
    [string]$ScriptId    = "52",
    [string]$Category    = "ContextMenuFixers",
    [string]$LeafName    = "",                # auto-derived from ScriptId if empty
    [ValidateSet("Auto", "All", "File", "Directory", "Background", "Desktop")]
    [string]$Scope       = "Auto",            # Auto = first hit; All = every hit
    [ValidateSet("Auto", "HKCR", "HKCU")]
    [string]$Hive        = "Auto",            # Auto = both; or pin one hive
    [int[]] $OnlyCases   = @(),               # empty = run all
    [switch]$NoColor,
    [switch]$DiscoverOnly,
    [switch]$Json,
    [string]$JsonPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---- §17.0 Reusable Variables (matches spec exactly) ----------------------
$SCRIPT_ID = $ScriptId
$CATEGORY  = $Category
$LEAF_NAME = if ([string]::IsNullOrWhiteSpace($LeafName)) {
    # Sensible default for the canonical demo script (52-vscode-folder-repair).
    if ($ScriptId -eq "52") { "$ScriptId-vscode-folder-repair" }
    else                    { "$ScriptId-unknown" }
} else { $LeafName }

# ---- Auto-mount registry drives PowerShell does not provide by default -----
#
# Why this is harder than it looks:
#   - PowerShell ships HKLM: and HKCU: by default in most hosts, but constrained
#     hosts (Constrained Language Mode, JEA endpoints, some embedded runspaces,
#     and PS Core in containers) may start with the Registry provider unloaded
#     OR with no built-in drives mounted at all.
#   - HKCR: is NEVER mounted by default in any host -- you always have to add it.
#   - New-PSDrive -Scope Script binds to THIS script's scope; if the harness
#     dot-sources or wraps a child runspace later, the drive disappears. We
#     mount with -Scope Global so all subsequent Test-Path / Get-ItemProperty
#     calls see it everywhere.
#   - A New-PSDrive call can "succeed" but the underlying provider may still
#     refuse access on first read (lazy load failures). We do an explicit
#     Test-Path probe after mounting and retry once on failure.
#
# Failure policy: HKCR is required (script 53 always installs there). HKCU is
# optional -- if it fails to mount we WARN (to stderr in -Json mode) and let
# the discovery loop simply not find HKCU candidates, instead of aborting.

# Capture mount diagnostics for the JSON document and human output.
$script:driveMountLog = @()

function Ensure-RegistryProvider {
    # Make sure the Registry provider is registered at all. On stripped-down
    # PS hosts it may need an explicit Import-Module Microsoft.PowerShell.Management.
    $hasProvider = (Get-PSProvider -ErrorAction SilentlyContinue |
                    Where-Object Name -eq 'Registry') -ne $null
    if (-not $hasProvider) {
        try { Import-Module Microsoft.PowerShell.Management -ErrorAction Stop -Force }
        catch {
            return [PSCustomObject]@{
                Ok      = $false
                Message = "Registry provider unavailable and Microsoft.PowerShell.Management failed to import: $_"
            }
        }
        $hasProvider = (Get-PSProvider -ErrorAction SilentlyContinue |
                        Where-Object Name -eq 'Registry') -ne $null
    }
    return [PSCustomObject]@{
        Ok      = [bool]$hasProvider
        Message = if ($hasProvider) { "Registry provider available" }
                  else              { "Registry provider still missing after Import-Module attempt" }
    }
}

function Ensure-RegDrive {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [string]$Root,
        [string]$ProbePath = $null,        # e.g. "HKCU:\Software" -- used to confirm the drive is alive
        [switch]$Required                  # if mount fails AND -Required, return Ok=false; else WARN only
    )

    $diag = [ordered]@{
        Drive    = $Name
        Root     = $Root
        Action   = ""
        Probe    = $ProbePath
        Ok       = $false
        Message  = ""
    }

    # 1. Already mounted? Probe-validate it before trusting it.
    $existing = Get-PSDrive -Name $Name -PSProvider Registry -ErrorAction SilentlyContinue
    if ($existing) {
        $diag.Action = "already-mounted"
        if ($ProbePath) {
            $isAlive = $false
            try { $isAlive = Test-Path -LiteralPath $ProbePath -ErrorAction Stop } catch { $isAlive = $false }
            if ($isAlive) {
                $diag.Ok = $true
                $diag.Message = "drive present and probe path resolved"
                $script:driveMountLog += [pscustomobject]$diag
                return $diag
            }
            # Stale / broken drive -- remove and re-mount below.
            $diag.Action = "remount-stale"
            try { Remove-PSDrive -Name $Name -Force -ErrorAction Stop } catch { }
        } else {
            $diag.Ok = $true
            $diag.Message = "drive present (no probe requested)"
            $script:driveMountLog += [pscustomobject]$diag
            return $diag
        }
    } else {
        $diag.Action = "mount"
    }

    # 2. Mount with -Scope Global so the drive survives nested function calls.
    #    Try Global first; fall back to Script scope if Global is not permitted
    #    (some constrained hosts forbid Global).
    $mountErr = $null
    $isMounted = $false
    foreach ($mountScope in @('Global', 'Script')) {
        try {
            New-PSDrive -Name $Name -PSProvider Registry -Root $Root -Scope $mountScope -ErrorAction Stop | Out-Null
            $isMounted = $true
            $diag.Message = "mounted at -Scope $mountScope"
            break
        } catch {
            $mountErr = $_
        }
    }

    if (-not $isMounted) {
        $diag.Ok      = $false
        $diag.Message = "New-PSDrive failed for both Global and Script scope: $mountErr"
        if (-not $Required) { $diag.Message += " (non-fatal -- $Name will be skipped)" }
        $script:driveMountLog += [pscustomobject]$diag
        return $diag
    }

    # 3. Verify the new drive actually responds. Some provider failures only
    #    surface on first read (e.g. a corrupted registry hive on the user
    #    profile, or an HKCU not yet loaded for a fresh login).
    if ($ProbePath) {
        $isAlive = $false
        try { $isAlive = Test-Path -LiteralPath $ProbePath -ErrorAction Stop } catch { $isAlive = $false }
        if (-not $isAlive) {
            # Retry once after a brief settle -- registry providers can race
            # against just-loaded user hives.
            Start-Sleep -Milliseconds 200
            try { $isAlive = Test-Path -LiteralPath $ProbePath -ErrorAction Stop } catch { $isAlive = $false }
        }
        if (-not $isAlive) {
            $diag.Ok      = $false
            $diag.Message = "$($diag.Message); but probe '$ProbePath' did not resolve after mount + retry"
            $script:driveMountLog += [pscustomobject]$diag
            return $diag
        }
    }

    $diag.Ok = $true
    $script:driveMountLog += [pscustomobject]$diag
    return $diag
}

# Pre-flight the Registry provider itself.
$providerStatus = Ensure-RegistryProvider
if (-not $providerStatus.Ok) {
    # We can't do anything without the provider. Defer the bail until JSON mode
    # is detected so we can emit a clean failure document.
    $script:registryProviderFatal = $providerStatus.Message
} else {
    $script:registryProviderFatal = ""
}

# HKCR is required by script 53's design.
$hkcrDiag = Ensure-RegDrive -Name HKCR -Root HKEY_CLASSES_ROOT `
                            -ProbePath "HKCR:\CLSID" -Required

# HKCU is optional. Probe at HKCU:\Software which exists on every loaded user
# profile; this catches the "fresh login, hive not yet attached" edge case.
$hkcuDiag = Ensure-RegDrive -Name HKCU -Root HKEY_CURRENT_USER `
                            -ProbePath "HKCU:\Software"

# ---- Output helpers --------------------------------------------------------
$script:results     = @()
$script:passN       = 0
$script:failN       = 0
$script:skipN       = 0
$script:currentScope = $null   # set per scope iteration; tagged onto each result
$script:currentHive  = $null

# In -Json mode, suppress console writes so stdout is pure JSON (pipeable).
# Use stderr for fatal pre-flight messages so callers can still see them.
function Write-C {
    param([string]$Text, [string]$Color = "White")
    if ($Json) { return }
    if ($NoColor) { Write-Host $Text }
    else          { Write-Host $Text -ForegroundColor $Color }
}

function Write-Err {
    param([string]$Text)
    # Always emit to stderr (visible even in -Json mode)
    [Console]::Error.WriteLine($Text)
}

function New-Result {
    param([string]$Name, [string]$Status, [string]$Detail = "")
    return [PSCustomObject]@{
        Case   = $script:currentCase
        Scope  = $script:currentScope
        Hive   = $script:currentHive
        Name   = $Name
        Status = $Status
        Detail = $Detail
    }
}

function Assert-True {
    param(
        [string]$Name,
        [bool]  $Condition,
        [string]$Detail = ""
    )
    if ($Condition) {
        $script:passN++
        $script:results += (New-Result -Name $Name -Status "PASS" -Detail $Detail)
        if ($VerbosePreference -eq "Continue") { Write-C "    [PASS] $Name" "Green" }
    } else {
        $script:failN++
        $script:results += (New-Result -Name $Name -Status "FAIL" -Detail $Detail)
        Write-C "    [FAIL] $Name" "Red"
        if ($Detail) { Write-C "           $Detail" "DarkGray" }
    }
}

function Skip-Case {
    param([string]$Reason)
    $script:skipN++
    $script:results += (New-Result -Name "(skipped)" -Status "SKIP" -Detail $Reason)
    Write-C "    [SKIP] $Reason" "Yellow"
}

function Should-Run {
    param([int]$CaseNum)
    if ($OnlyCases.Count -eq 0) { return $true }
    return ($OnlyCases -contains $CaseNum)
}

function Start-Case {
    param([int]$Num, [string]$Title)
    $script:currentCase = $Num
    Write-C ""
    Write-C "Case $Num : $Title" "Cyan"
}

# ---- §17.0 Helper functions (matches spec exactly) ------------------------
function Test-LeafExists($Path) { Test-Path $Path }
function Get-ExtendedValue($Path) {
    Get-ItemProperty $Path -Name "Extended" -ErrorAction SilentlyContinue
}
function Get-LeafCommand($Path) {
    $cmdPath = Join-Path $Path "command"
    $prop = Get-ItemProperty $cmdPath -Name "(Default)" -ErrorAction SilentlyContinue
    if ($null -eq $prop) { return $null }
    # Default value lives under the property whose name PS exposes as "(default)"
    return $prop.'(default)'
}

# ===========================================================================
#  PRE-FLIGHT  --  Scope auto-detection
#
#  Build a candidate matrix of (Hive x Scope) and probe each for the
#  ScriptFixer top-key. Skip mode: probe-only; user passes -Scope <name>
#  and we honor it. Auto mode: walk all candidates, pick the FIRST hit and
#  run cases against it. All mode: run cases against EVERY hit (one section
#  per scope), aggregating into the same pass/fail counters.
# ===========================================================================

# Scope catalog: name -> { Hive ; PsRoot ; RegRoot }
#   PsRoot is the PowerShell-drive form ("HKCR:\*")
#   RegRoot is the reg.exe form        ("HKCR\*")  (sans the drive colon + backslash prefix)
$SCOPE_CATALOG = @(
    @{ Name = "File";       Hive = "HKCR"; PsRoot = "HKCR:\*";                            RegRoot = "HKCR\*" }
    @{ Name = "Directory";  Hive = "HKCR"; PsRoot = "HKCR:\Directory";                    RegRoot = "HKCR\Directory" }
    @{ Name = "Background"; Hive = "HKCR"; PsRoot = "HKCR:\Directory\Background";         RegRoot = "HKCR\Directory\Background" }
    @{ Name = "Desktop";    Hive = "HKCR"; PsRoot = "HKCR:\DesktopBackground";            RegRoot = "HKCR\DesktopBackground" }
    # Per-user (HKCU) mirrors -- script 53 does not currently install here, but the
    # harness will detect them if a future config writes per-user keys.
    @{ Name = "File";       Hive = "HKCU"; PsRoot = "HKCU:\Software\Classes\*";                    RegRoot = "HKCU\Software\Classes\*" }
    @{ Name = "Directory";  Hive = "HKCU"; PsRoot = "HKCU:\Software\Classes\Directory";            RegRoot = "HKCU\Software\Classes\Directory" }
    @{ Name = "Background"; Hive = "HKCU"; PsRoot = "HKCU:\Software\Classes\Directory\Background"; RegRoot = "HKCU\Software\Classes\Directory\Background" }
    @{ Name = "Desktop";    Hive = "HKCU"; PsRoot = "HKCU:\Software\Classes\DesktopBackground";    RegRoot = "HKCU\Software\Classes\DesktopBackground" }
)

# Apply -Hive filter
$candidates = $SCOPE_CATALOG | Where-Object {
    ($Hive -eq "Auto") -or ($_.Hive -eq $Hive)
}

# Apply -Scope filter (Auto/All means "all candidates"; otherwise pin to one name)
if ($Scope -ne "Auto" -and $Scope -ne "All") {
    $candidates = @($candidates | Where-Object { $_.Name -eq $Scope })
}

Write-C ""
Write-C "================================================================" "DarkCyan"
Write-C " Script Fixer (53) -- spec section 17 test harness"             "DarkCyan"
Write-C "================================================================" "DarkCyan"
Write-C "  ScriptId      : $SCRIPT_ID"
Write-C "  Category      : $CATEGORY"
Write-C "  LeafName      : $LEAF_NAME"
Write-C "  Scope mode    : $Scope"
Write-C "  Hive filter   : $Hive"
Write-C ""

# Print drive-mount diagnostics so users can see WHY HKCU probes were skipped.
Write-C "  Registry drives:" "White"
foreach ($d in $script:driveMountLog) {
    $okMarker = if ($d.Ok) { "[ok]" } else { "[!! ]" }
    $color    = if ($d.Ok) { "Green" } else { "Yellow" }
    Write-C ("    {0} {1,-5} {2,-12} {3}" -f $okMarker, $d.Drive, $d.Action, $d.Message) $color
}
Write-C ""

# If the Registry provider itself failed, abort cleanly.
if ($script:registryProviderFatal) {
    if ($Json) {
        # JSON path needs probeRows to exist; build an empty discovery for shape stability.
        $probeRows = @()
        $hits = @()
        Emit-JsonAndExit -Mode "discover" -ExitCode 2 -FatalMessage $script:registryProviderFatal
    }
    Write-C "FATAL: $($script:registryProviderFatal)" "Red"
    exit 2
}

# If HKCR failed (required), abort. HKCU failure is a soft warning.
if (-not $hkcrDiag.Ok) {
    $msg = "HKCR drive could not be mounted: $($hkcrDiag.Message)"
    if ($Json) {
        $probeRows = @()
        $hits = @()
        Emit-JsonAndExit -Mode "discover" -ExitCode 2 -FatalMessage $msg
    }
    Write-C "FATAL: $msg" "Red"
    exit 2
}

# Drop HKCU candidates from the catalog if the drive isn't usable, so we don't
# waste time probing paths that will all return false anyway.
if (-not $hkcuDiag.Ok) {
    Write-C "  WARN: HKCU drive unusable -- skipping all HKCU candidates." "Yellow"
    $candidates = @($candidates | Where-Object { $_.Hive -ne 'HKCU' })
    Write-C ""
}

# Probe every candidate; build a hit table
$probeRows = foreach ($c in $candidates) {
    $menuRoot = Join-Path $c.PsRoot "shell\ScriptFixer"
    $isHit    = Test-Path -LiteralPath $menuRoot -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Hive     = $c.Hive
        Scope    = $c.Name
        PsRoot   = $c.PsRoot
        RegRoot  = $c.RegRoot
        MenuRoot = $menuRoot
        IsHit    = [bool]$isHit
    }
}

# Print discovery table
Write-C "  Scope discovery:" "White"
foreach ($row in $probeRows) {
    $marker = if ($row.IsHit) { "[hit]" } else { "[ -- ]" }
    $color  = if ($row.IsHit) { "Green" } else { "DarkGray" }
    Write-C ("    {0} {1,-10} {2,-5} {3}" -f $marker, $row.Scope, $row.Hive, $row.MenuRoot) $color
}
Write-C ""

$hits = @($probeRows | Where-Object IsHit)

# ---- Emit-JSON helper ------------------------------------------------------
function Emit-JsonAndExit {
    param(
        [string]   $Mode,           # "discover" | "verify"
        [int]      $ExitCode,
        [string]   $FatalMessage = ""
    )
    $doc = [ordered]@{
        timestamp   = (Get-Date).ToString("o")
        scriptId    = $SCRIPT_ID
        category    = $CATEGORY
        leafName    = $LEAF_NAME
        mode        = $Mode
        scopeFilter = $Scope
        hiveFilter  = $Hive
        driveMounts = @($script:driveMountLog | ForEach-Object {
            [ordered]@{
                drive   = $_.Drive
                root    = $_.Root
                action  = $_.Action
                probe   = $_.Probe
                ok      = [bool]$_.Ok
                message = $_.Message
            }
        })
        discovery   = @($probeRows | ForEach-Object {
            [ordered]@{
                hive     = $_.Hive
                scope    = $_.Scope
                psRoot   = $_.PsRoot
                regRoot  = $_.RegRoot
                menuRoot = $_.MenuRoot
                hit      = [bool]$_.IsHit
            }
        })
        hitCount    = $hits.Count
        fatal       = $FatalMessage
        summary     = [ordered]@{
            pass = $script:passN
            fail = $script:failN
            skip = $script:skipN
        }
        results     = @($script:results | ForEach-Object {
            [ordered]@{
                case   = $_.Case
                scope  = $_.Scope
                hive   = $_.Hive
                name   = $_.Name
                status = $_.Status
                detail = $_.Detail
            }
        })
        exitCode    = $ExitCode
    }
    $payload = $doc | ConvertTo-Json -Depth 6
    if ([string]::IsNullOrWhiteSpace($JsonPath)) {
        Write-Output $payload
    } else {
        try {
            $payload | Set-Content -LiteralPath $JsonPath -Encoding UTF8
            Write-Err "JSON written to: $JsonPath"
        } catch {
            Write-Err "ERROR: failed to write JSON to '$JsonPath' -- $_"
            $ExitCode = 2
        }
    }
    exit $ExitCode
}

# ---- Pre-flight: no hits at all -------------------------------------------
if ($hits.Count -eq 0) {
    $msg = "ScriptFixer menu not installed under any probed scope/hive."
    if ($Json) { Emit-JsonAndExit -Mode "discover" -ExitCode 2 -FatalMessage $msg }
    Write-C "FATAL: $msg" "Red"
    Write-C "Run '.\run.ps1 -I 53 install' from an admin shell first." "Yellow"
    exit 2
}

# ---- Discover-only mode ----------------------------------------------------
if ($DiscoverOnly) {
    if ($Json) { Emit-JsonAndExit -Mode "discover" -ExitCode 0 }
    Write-C "================================================================" "DarkCyan"
    Write-C " Discover-only mode -- scope/hive detection complete"           "DarkCyan"
    Write-C "================================================================" "DarkCyan"
    Write-C ""
    Write-C "Found $($hits.Count) installed scope(s):" "Green"
    foreach ($hit in $hits) {
        Write-C "    - $($hit.Scope) on $($hit.Hive) at $($hit.MenuRoot)" "White"
    }
    Write-C ""
    Write-C "To run full verification cases, omit -DiscoverOnly." "Yellow"
    exit 0
}

# Decide which scopes to run cases against
$runScopes = if ($Scope -eq "All") {
    $hits
} else {
    # Auto OR explicit scope -- pick the first hit (deterministic catalog order)
    @($hits | Select-Object -First 1)
}

if ($Scope -eq "Auto" -and $hits.Count -gt 1) {
    Write-C ("  Auto-selected: {0} ({1}). Pass -Scope All to run cases against every hit." -f $runScopes[0].Scope, $runScopes[0].Hive) "Yellow"
    Write-C ""
}

# ===========================================================================
#  CASE BLOCK  --  Repeated for each selected scope
# ===========================================================================
$script:overallPass = 0  # snapshot for per-scope summary
$script:overallFail = 0
$script:overallSkip = 0

foreach ($sel in $runScopes) {
    $SCOPE_ROOT    = $sel.PsRoot
    $REG_BASE      = $sel.RegRoot
    $MENU_ROOT     = $sel.MenuRoot
    $CATEGORY_ROOT = Join-Path $MENU_ROOT "shell\$CATEGORY"
    $DEFAULT_LEAF  = Join-Path $CATEGORY_ROOT "shell\$LEAF_NAME"
    $BYPASS_LEAF   = Join-Path $CATEGORY_ROOT "shell\$LEAF_NAME-NoPrompt"

    # Tag results with the scope/hive currently under test (used by -Json output)
    $script:currentScope = $sel.Scope
    $script:currentHive  = $sel.Hive

    Write-C "================================================================" "DarkGray"
    Write-C (" Running cases against: {0} / {1}" -f $sel.Scope, $sel.Hive)     "White"
    Write-C "================================================================" "DarkGray"
    Write-C "  Default leaf  : $DEFAULT_LEAF" "DarkGray"
    Write-C "  Bypass leaf   : $BYPASS_LEAF"  "DarkGray"


# ===========================================================================
#  CASE 6 -- Default leaf has no Extended value; bypass leaf has it
# ===========================================================================
if (Should-Run 6) {
    Start-Case 6 "Shift-bypass leaf is hidden by default (Extended attribute)"
    $defaultExists  = Test-LeafExists $DEFAULT_LEAF
    Assert-True "Default leaf exists at $DEFAULT_LEAF" $defaultExists

    if ($defaultExists) {
        $defaultExtended = Get-ExtendedValue $DEFAULT_LEAF
        Assert-True "Default leaf has NO Extended value" ($null -eq $defaultExtended) `
            "Got: $defaultExtended"
    } else { Skip-Case "default leaf missing" }

    $bypassExists = Test-LeafExists $BYPASS_LEAF
    Assert-True "Bypass leaf exists at $BYPASS_LEAF" $bypassExists `
        "(only valid when emitBypassLeaves: true)"

    if ($bypassExists) {
        $bypassExtended = Get-ExtendedValue $BYPASS_LEAF
        Assert-True "Bypass leaf HAS Extended value" ($null -ne $bypassExtended)
    }
}

# ===========================================================================
#  CASE 7 -- Programmatic Extended audit across the category subtree
# ===========================================================================
if (Should-Run 7) {
    Start-Case 7 "All -NoPrompt leaves have Extended; all default leaves do NOT"
    $allLeaves = Get-ChildItem -Path $CATEGORY_ROOT -Recurse -ErrorAction SilentlyContinue |
                 Where-Object { $_.PSChildName -like "*$SCRIPT_ID*" }

    $audit = $allLeaves | ForEach-Object {
        $hasExt = (Get-ExtendedValue $_.PSPath) -ne $null
        [PSCustomObject]@{
            Leaf        = $_.PSChildName
            HasExtended = $hasExt
            IsBypass    = ($_.PSChildName -like "*-NoPrompt")
        }
    }

    if ($audit.Count -eq 0) { Skip-Case "no leaves found under $CATEGORY_ROOT for id $SCRIPT_ID" }

    foreach ($row in $audit) {
        if ($row.IsBypass) {
            Assert-True "Bypass leaf '$($row.Leaf)' has Extended" $row.HasExtended
        } else {
            Assert-True "Default leaf '$($row.Leaf)' has NO Extended" (-not $row.HasExtended)
        }
    }
}

# ===========================================================================
#  CASE 8 -- reg.exe exit-code + REG_SZ + empty-string verification
# ===========================================================================
if (Should-Run 8) {
    Start-Case 8 "Extended is REG_SZ + empty on bypass; absent on default (reg.exe + .NET)"

    # ---- reg.exe exit codes ----
    $bypassRaw = reg.exe query "$REG_BASE\shell\ScriptFixer\shell\$CATEGORY\shell\$LEAF_NAME-NoPrompt" /v Extended 2>&1
    $bypassExit = $LASTEXITCODE
    Assert-True "reg.exe finds Extended on bypass leaf (exit 0)" ($bypassExit -eq 0) `
        "Exit=$bypassExit"

    $defaultRaw = reg.exe query "$REG_BASE\shell\ScriptFixer\shell\$CATEGORY\shell\$LEAF_NAME" /v Extended 2>&1
    $defaultExit = $LASTEXITCODE
    Assert-True "reg.exe does NOT find Extended on default leaf (exit 1)" ($defaultExit -eq 1) `
        "Exit=$defaultExit"

    # ---- Strict type + value parsing of reg.exe output ----
    $bypassLine = $bypassRaw | Where-Object { $_ -match '^\s*Extended\s+REG_SZ' }
    Assert-True "Bypass leaf Extended is typed REG_SZ" ([bool]$bypassLine) `
        "Lines: $($bypassRaw -join ' | ')"

    if ([bool]$bypassLine) {
        $isEmpty = $bypassLine -match '^\s*Extended\s+REG_SZ\s*$'
        Assert-True "Bypass leaf Extended value is empty string" $isEmpty `
            "Line: $bypassLine"
    }

    # ---- .NET-level type introspection (most authoritative) ----
    try {
        # Strip the PS-drive prefix (HKCR:\ or HKCU:\) to get a hive-relative subkey
        $bypassSubKey  = $BYPASS_LEAF  -replace '^(HKCR|HKCU):\\', ''
        $defaultSubKey = $DEFAULT_LEAF -replace '^(HKCR|HKCU):\\', ''

        # Pick the right hive root for .NET
        $hiveRoot = if ($sel.Hive -eq "HKCU") {
            [Microsoft.Win32.Registry]::CurrentUser
        } else {
            [Microsoft.Win32.Registry]::ClassesRoot
        }

        $bk = $hiveRoot.OpenSubKey($bypassSubKey)
        if ($null -ne $bk) {
            $kind  = $bk.GetValueKind("Extended")
            $value = $bk.GetValue("Extended")
            $bk.Close()
            Assert-True ".NET: bypass Extended kind = String (REG_SZ)" `
                ($kind -eq [Microsoft.Win32.RegistryValueKind]::String) "Kind=$kind"
            Assert-True ".NET: bypass Extended value is empty string" `
                ($value -is [string] -and $value -eq "") "Value='$value'"
        } else {
            Skip-Case ".NET could not open bypass subkey $bypassSubKey under $($sel.Hive)"
        }

        $dk = $hiveRoot.OpenSubKey($defaultSubKey)
        if ($null -ne $dk) {
            $defVal = $dk.GetValue("Extended", $null)
            $dk.Close()
            Assert-True ".NET: default Extended is null (absent)" ($null -eq $defVal) `
                "Value=$defVal"
        } else {
            Skip-Case ".NET could not open default subkey $defaultSubKey under $($sel.Hive)"
        }
    } catch {
        Assert-True ".NET registry introspection threw: $_" $false
    }
}

# ===========================================================================
#  CASE 9 -- /s /f search returns both leaves for a given script id
# ===========================================================================
if (Should-Run 9) {
    Start-Case 9 "reg.exe /s /f finds both default and bypass leaves for $LEAF_NAME"
    $hits = reg.exe query "$REG_BASE\shell\ScriptFixer\shell" /s /f $LEAF_NAME 2>$null |
            Select-String -Pattern $LEAF_NAME
    $hitCount = ($hits | Measure-Object).Count
    Assert-True "Found at least 2 hits for '$LEAF_NAME' (default + bypass key headers)" `
        ($hitCount -ge 2) "Hit count: $hitCount"
}

# ===========================================================================
#  CASE 10 -- Uninstall removal verification (read-only check)
# ===========================================================================
if (Should-Run 10) {
    Start-Case 10 "Top ScriptFixer key state (read-only post-install check)"
    $null = reg.exe query "$REG_BASE\shell\ScriptFixer" 2>$null
    $exit = $LASTEXITCODE
    Assert-True "Menu IS installed (reg.exe exit 0)" ($exit -eq 0) `
        "Exit=$exit. After running uninstall, this case should be re-run; expected exit 1."
}

# ===========================================================================
#  CASE 11 -- Idempotency: no double "-NoPrompt-NoPrompt" suffixes
# ===========================================================================
if (Should-Run 11) {
    Start-Case 11 "Idempotency -- no '-NoPrompt-NoPrompt' double suffixes"
    $double = reg.exe query "$REG_BASE\shell\ScriptFixer" /s 2>$null |
              Select-String -Pattern "-NoPrompt-NoPrompt"
    $dupCount = ($double | Measure-Object).Count
    Assert-True "Zero double-suffixed keys" ($dupCount -eq 0) "Found: $dupCount"
}

# ===========================================================================
#  CASE 12 -- emitBypassLeaves audit (informational; respects current config)
# ===========================================================================
if (Should-Run 12) {
    Start-Case 12 "emitBypassLeaves audit -- counts default vs bypass leaves under category"
    $allLeaves = Get-ChildItem -Path "$CATEGORY_ROOT\shell" -ErrorAction SilentlyContinue |
                 Where-Object { $_.PSChildName -match "^\d+" }

    $defaults = @($allLeaves | Where-Object { $_.PSChildName -notlike "*-NoPrompt" })
    $bypasses = @($allLeaves | Where-Object { $_.PSChildName -like     "*-NoPrompt" })

    Write-C "    Default leaves : $($defaults.Count)" "DarkGray"
    Write-C "    Bypass leaves  : $($bypasses.Count)" "DarkGray"

    Assert-True "At least one default leaf exists" ($defaults.Count -ge 1)

    if ($bypasses.Count -eq 0) {
        Write-C "    Note: emitBypassLeaves appears to be FALSE (no -NoPrompt keys)." "Yellow"
        Assert-True "When suppressed, bypass count is exactly 0" ($bypasses.Count -eq 0)
    } else {
        Assert-True "Bypass count matches default count (1:1 pairing)" `
            ($bypasses.Count -eq $defaults.Count) `
            "$($bypasses.Count) bypass vs $($defaults.Count) default"
    }
}

# ===========================================================================
#  CASE 13 -- Command template inspection (legacy vs confirm-launch mode)
# ===========================================================================
if (Should-Run 13) {
    Start-Case 13 "Command template inspection (confirm-launch.ps1 in path?)"
    $cmd = Get-LeafCommand $DEFAULT_LEAF
    if ($null -eq $cmd) {
        Skip-Case "default leaf has no command value (path: $DEFAULT_LEAF\command)"
    } else {
        Write-C "    Command: $cmd" "DarkGray"
        $usesWrapper = $cmd -match 'confirm-launch\.ps1'
        $usesDirect  = $cmd -match "run\.ps1.*-I\s+$SCRIPT_ID"

        # We do not assert which mode -- we report which one is active.
        if ($usesWrapper) {
            Assert-True "confirmBeforeLaunch.enabled = true (wrapper present)" $true
        } elseif ($usesDirect) {
            Assert-True "confirmBeforeLaunch.enabled = false (legacy direct dispatch)" $true
        } else {
            Assert-True "Command matches one of the two known templates" $false `
                "Neither 'confirm-launch.ps1' nor 'run.ps1 -I $SCRIPT_ID' found in command"
        }
    }
}

    # ---- Per-scope footer ----
    $scopePass = $script:passN - $script:overallPass
    $scopeFail = $script:failN - $script:overallFail
    $scopeSkip = $script:skipN - $script:overallSkip
    Write-C ""
    Write-C ("  -- {0}/{1} sub-totals: PASS={2}  FAIL={3}  SKIP={4}" -f $sel.Scope, $sel.Hive, $scopePass, $scopeFail, $scopeSkip) `
        $(if ($scopeFail -gt 0) { "Red" } else { "Green" })
    $script:overallPass = $script:passN
    $script:overallFail = $script:failN
    $script:overallSkip = $script:skipN
    Write-C ""
}

# ===========================================================================
#  SUMMARY
# ===========================================================================
$finalExit = if ($script:failN -gt 0) { 1 } else { 0 }

if ($Json) {
    Emit-JsonAndExit -Mode "verify" -ExitCode $finalExit
}

Write-C ""
Write-C "================================================================" "DarkCyan"
Write-C " Summary (across $($runScopes.Count) scope(s))"                    "DarkCyan"
Write-C "================================================================" "DarkCyan"
Write-C "  PASS : $script:passN" "Green"
Write-C "  FAIL : $script:failN" $(if ($script:failN -gt 0) { "Red" } else { "DarkGray" })
Write-C "  SKIP : $script:skipN" "Yellow"
Write-C ""

if ($script:failN -gt 0) {
    Write-C "Failures:" "Red"
    $script:results | Where-Object Status -eq "FAIL" | ForEach-Object {
        Write-C ("  [Case {0}] {1}" -f $_.Case, $_.Name) "Red"
        if ($_.Detail) { Write-C ("            {0}" -f $_.Detail) "DarkGray" }
    }
    exit 1
}

Write-C "All cases passed." "Green"
exit 0
