# 03 -- WhatsApp Install

**Script ID**: 49
**Folder**: `scripts/49-install-whatsapp/`
**Keywords**: `whatsapp`, `wa`
**OS-dir install**: yes (Store-style desktop app)
**Mechanism**: Chocolatey (`choco install whatsapp -y`) -- NOT Microsoft Store

## What it does

Installs WhatsApp Desktop via Chocolatey. Skips the Microsoft Store path entirely (per locked decision).

## Implementation

### `scripts/49-install-whatsapp/config.json`
```json
{
  "whatsapp": {
    "enabled": true,
    "chocoPackage": "whatsapp",
    "skipDevDirPrompt": true,
    "fallback": {
      "enabled": true,
      "url": "https://web.whatsapp.com/desktop/windows/release/x64/WhatsAppSetup.exe",
      "fileName": "WhatsAppSetup.exe",
      "downloadDir": "",
      "silentArgs": "/S",
      "timeoutSeconds": 600
    },
    "uninstallCleanup": {
      "enabled": true,
      "removeRegistryKeys": true,
      "removeShortcuts": true,
      "registryKeys": ["HKCU:\\Software\\WhatsApp", "HKLM:\\SOFTWARE\\WhatsApp", "..."],
      "shortcutPaths": ["%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\WhatsApp.lnk", "%USERPROFILE%\\Desktop\\WhatsApp.lnk", "..."],
      "appDataPaths": ["%LOCALAPPDATA%\\WhatsApp"],
      "purgeAppData": false
    }
  }
}
```

### `scripts/49-install-whatsapp/run.ps1`
Standard single-tool pattern:
1. `Initialize-Logging -ScriptName "Install WhatsApp"`
2. `Assert-Choco`
3. `Install-ChocoPackage -Name "whatsapp"` (or upgrade if installed)
4. Verify: `Test-Path "$env:LOCALAPPDATA\WhatsApp\WhatsApp.exe"` OR `Get-Command whatsapp -ErrorAction SilentlyContinue`
5. **Fallback (NEW):** if step 3 returns failure OR step 4 verify fails, call `Invoke-WhatsAppOfficialInstaller`:
   - Download `WhatsAppSetup.exe` from `config.whatsapp.fallback.url` into `$env:TEMP` (or `fallback.downloadDir`).
   - Refuse to run if file is `< 1 MB` (clearly corrupted/stub).
   - `Start-Process -FilePath <dest> -ArgumentList "/S" -PassThru -WindowStyle Hidden`, wait up to `timeoutSeconds`.
   - Re-run `Get-WhatsAppPath` verify. Record install with method `"official-installer"`.
6. `Save-LogFile -Status "ok"`

### Uninstall flow (`Uninstall-WhatsApp` in `helpers/whatsapp.ps1`)

1. `Uninstall-ChocoPackage -PackageName "whatsapp"` (failure here is now `warn`-level, not terminal -- the sweep below can still recover state).
2. **Sweep stage (`Invoke-WaPostUninstallCleanup`)** -- only runs if `config.whatsapp.uninstallCleanup.enabled = true`:
   - **Registry sweep** (`Remove-WaRegistryKeys`): for each entry in `registryKeys`, `Test-Path` then `Remove-Item -Recurse -Force`. Counts removed / missing / failed.
   - **Shortcut sweep** (`Remove-WaShortcuts`): for each entry in `shortcutPaths` (with `%ENV%` expansion), delete `.lnk` files or Start Menu folders. Handles file vs. container automatically.
   - **AppData sweep**: opt-in -- entries in `appDataPaths` are logged as "kept" unless `purgeAppData = true`, in which case `%LOCALAPPDATA%\WhatsApp` is recursively removed.
   - **Summary line**: prints all six counters (`reg removed/missing/failed`, `shortcut removed/missing/failed`); `success` if zero failures, `warn` otherwise.
3. `Remove-InstalledRecord -Name "whatsapp"`
4. `Remove-ResolvedData -ScriptFolder "49-install-whatsapp"`
5. `Save-LogFile -Status "ok"`

## Registry + keyword wiring

- `scripts/registry.json`: `"49": "49-install-whatsapp"`
- `scripts/shared/install-keywords.json`: `"whatsapp": [49]`, `"wa": [49]`

## Verification

```powershell
.\run.ps1 install whatsapp
.\run.ps1 -I 49
.\run.ps1 -I 49 uninstall   # now sweeps registry + shortcuts after choco
```

To force-test the fallback path without breaking choco, temporarily set
`config.whatsapp.chocoPackage` to a bogus value (e.g. `"whatsapp-does-not-exist"`)
and re-run -- the script should download the official installer and complete.

To dry-run the uninstall sweep without actually uninstalling, point
`config.whatsapp.chocoPackage` at a no-op package and inspect the per-key /
per-shortcut log lines.

## Resolved questions

- ✅ **Stale Chocolatey package** -- if `choco install whatsapp` fails or the
  install verify step cannot find `WhatsApp.exe`, the script now falls back to
  downloading `https://web.whatsapp.com/desktop/windows/release/x64/WhatsAppSetup.exe`
  and running it silently with `/S`. Controlled by `config.whatsapp.fallback.enabled`.
