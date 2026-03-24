# ---------------------------------------------------------------------------
# uninstall.ps1 - Remove ServiceNow config items from OpenCode config dir
#
# Removes the known files and directories installed by install.ps1.
# Use -Yes to skip the confirmation prompt.
# PowerShell 5.1+ compatible.
# ---------------------------------------------------------------------------

#Requires -Version 5.1

param(
    [switch]$Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -- Resolve paths ----------------------------------------------------------

$ConfigDir = Join-Path $env:USERPROFILE ".config\opencode"

# -- State ------------------------------------------------------------------

$Removed = 0

# -- Guard: nothing to do if config dir missing -----------------------------

if (-not (Test-Path $ConfigDir)) {
    Write-Host "Nothing to do - OpenCode config directory does not exist."
    exit 0
}

# -- Confirmation prompt ----------------------------------------------------

if (-not $Yes) {
    $answer = Read-Host "This will remove 12 ServiceNow config items from ~/.config/opencode/. Continue? [y/N]"
    if ($answer -notmatch '^[yY]') {
        Write-Host "Aborted."
        exit 0
    }
}

# -- Removal helpers --------------------------------------------------------

function Remove-ConfigFile {
    param(
        [string]$Target,
        [string]$Label
    )

    if (-not (Test-Path $Target)) {
        return
    }

    Remove-Item $Target -Force
    Write-Host -NoNewline -ForegroundColor Green "[ok] "
    Write-Host "Removed $Label"
    $script:Removed++
}

function Remove-ConfigDir {
    param(
        [string]$Target,
        [string]$Label
    )

    if (-not (Test-Path $Target)) {
        return
    }

    Remove-Item $Target -Recurse -Force
    Write-Host -NoNewline -ForegroundColor Green "[ok] "
    Write-Host "Removed $Label"
    $script:Removed++
}

# -- Agents -----------------------------------------------------------------

Write-Host "Agents:"
foreach ($name in @("servicenow.md", "servicenow-dev.md")) {
    Remove-ConfigFile -Target (Join-Path $ConfigDir "agents\$name") -Label $name
    Remove-ConfigFile -Target (Join-Path $ConfigDir "agent\$name") -Label $name
}

# -- Skills -----------------------------------------------------------------

Write-Host ""
Write-Host "Skills:"
foreach ($name in @("servicenow-scripting", "servicenow-business-rules", "servicenow-client-scripts", "servicenow-gliderecord")) {
    Remove-ConfigDir -Target (Join-Path $ConfigDir "skills\$name") -Label $name
    Remove-ConfigDir -Target (Join-Path $ConfigDir "skill\$name") -Label $name
}

# -- Commands ---------------------------------------------------------------

Write-Host ""
Write-Host "Commands:"
foreach ($name in @("sn-write", "sn-debug", "sn-health", "sn-logic-map", "sn-review", "sn-updateset")) {
    Remove-ConfigFile -Target (Join-Path $ConfigDir "commands\$name.md") -Label "$name.md"
    Remove-ConfigFile -Target (Join-Path $ConfigDir "command\$name.md") -Label "$name.md"
}

# -- Summary ----------------------------------------------------------------

Write-Host ""
Write-Host "Done! $Removed items removed."
