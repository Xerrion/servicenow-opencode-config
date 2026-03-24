# ---------------------------------------------------------------------------
# uninstall.ps1 - Remove symlinks created by install.ps1
#
# Safety: Only removes symlinks that point back into this repo.
#         Regular files and foreign symlinks are never touched.
# PowerShell 5.1+ compatible.
# ---------------------------------------------------------------------------

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -- Resolve paths ----------------------------------------------------------

$ScriptDir = $PSScriptRoot
$ConfigDir = Join-Path $env:USERPROFILE ".config\opencode"

# -- State ------------------------------------------------------------------

$Removed = 0
$Skipped = 0

# -- Guard: nothing to do if config dir missing -----------------------------

if (-not (Test-Path $ConfigDir)) {
    Write-Host "Nothing to do - OpenCode config directory does not exist."
    exit 0
}

# -- Removal helper ---------------------------------------------------------

function Remove-RepoSymlink {
    param(
        [string]$Target,
        [string]$Label
    )

    # Does not exist - skip silently
    if (-not (Test-Path $Target)) {
        return
    }

    $item = Get-Item $Target -Force

    # Not a symlink - never touch regular files or directories
    $isSymlink = $item.Attributes -band [IO.FileAttributes]::ReparsePoint
    if (-not $isSymlink) {
        Write-Host -NoNewline -ForegroundColor Yellow "-> "
        Write-Host "Skipped $Label (not a symlink)"
        $script:Skipped++
        return
    }

    # Symlink exists - check if it points into our repo
    $linkTarget = $item.Target

    # Target may be returned as an array in some PS versions
    if ($linkTarget -is [array]) {
        $linkTarget = $linkTarget[0]
    }

    # Resolve to absolute path for reliable comparison
    if ($linkTarget -and -not [IO.Path]::IsPathRooted($linkTarget)) {
        $linkTarget = [IO.Path]::GetFullPath((Join-Path (Split-Path $Target) $linkTarget))
    }

    if ($linkTarget -and $linkTarget.StartsWith($ScriptDir, [StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item $Target -Force
        Write-Host -NoNewline -ForegroundColor Green "[ok] "
        Write-Host "Removed $Label"
        $script:Removed++
    }
    else {
        Write-Host -NoNewline -ForegroundColor Yellow "-> "
        Write-Host "Skipped $Label (not managed by this repo)"
        $script:Skipped++
    }
}

# -- Agents -----------------------------------------------------------------

Write-Host "Agents:"
foreach ($name in @("servicenow.md", "servicenow-dev.md")) {
    Remove-RepoSymlink -Target (Join-Path $ConfigDir "agents\$name") -Label $name
    Remove-RepoSymlink -Target (Join-Path $ConfigDir "agent\$name") -Label $name
}

# -- Skills -----------------------------------------------------------------

Write-Host ""
Write-Host "Skills:"
foreach ($name in @("servicenow-scripting", "servicenow-business-rules", "servicenow-client-scripts", "servicenow-gliderecord")) {
    Remove-RepoSymlink -Target (Join-Path $ConfigDir "skills\$name") -Label $name
    Remove-RepoSymlink -Target (Join-Path $ConfigDir "skill\$name") -Label $name
}

# -- Commands ---------------------------------------------------------------

Write-Host ""
Write-Host "Commands:"
foreach ($name in @("sn-write", "sn-debug", "sn-health", "sn-logic-map", "sn-review", "sn-updateset")) {
    Remove-RepoSymlink -Target (Join-Path $ConfigDir "commands\$name.md") -Label "$name.md"
    Remove-RepoSymlink -Target (Join-Path $ConfigDir "command\$name.md") -Label "$name.md"
}

# -- Summary ----------------------------------------------------------------

Write-Host ""
Write-Host "Done! $Removed items removed, $Skipped skipped."
