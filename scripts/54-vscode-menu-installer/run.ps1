# --------------------------------------------------------------------------
#  Script 54 -- run.ps1 (router)
#
#  Routes to install.ps1 / uninstall.ps1 so the project's master -I 54
#  dispatcher can invoke this script with a verb.
# --------------------------------------------------------------------------
param(
    [Parameter(Position = 0)]
    [string]$Command = "install",

    [string]$Edition,
    [string]$VsCodePath,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest = @(),

    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

if ($Help) {
    & (Join-Path $scriptDir "install.ps1") -Help
    return
}

switch ($Command.ToLower()) {
    "uninstall" {
        & (Join-Path $scriptDir "uninstall.ps1") -Edition $Edition
    }
    "verify" {
        $harness = Join-Path $scriptDir "tests\run-tests.ps1"
        $isHarnessMissing = -not (Test-Path -LiteralPath $harness)
        if ($isHarnessMissing) {
            Write-Host "FATAL: test harness not found -- expected at: $harness" -ForegroundColor Red
            exit 2
        }
        $passthrough = @()
        if (-not [string]::IsNullOrWhiteSpace($Edition)) { $passthrough += @('-Edition', $Edition) }
        if ($Rest.Count -gt 0) { $passthrough += $Rest }
        & $harness @passthrough
        exit $LASTEXITCODE
    }
    default {
        & (Join-Path $scriptDir "install.ps1") -Edition $Edition -VsCodePath $VsCodePath
    }
}
