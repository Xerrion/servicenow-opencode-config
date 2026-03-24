# ---------------------------------------------------------------------------
# install.ps1 - Symlink ServiceNow agents, skills, and commands into OpenCode
#
# Usage: .\install.ps1 [-Force]
#   -Force  Replace existing files/symlinks instead of skipping
# ---------------------------------------------------------------------------

[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -- Guard: Symlink capability check ----------------------------------------
# Windows requires Developer Mode enabled or running as Administrator to
# create symlinks. Check both before proceeding.

function Test-SymlinkCapability {
    # Check Developer Mode via registry
    $devModePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (Test-Path $devModePath) {
        $devMode = Get-ItemProperty -Path $devModePath -Name "AllowDevelopmentWithoutDevLicense" -ErrorAction SilentlyContinue
        if ($devMode -and $devMode.AllowDevelopmentWithoutDevLicense -eq 1) {
            return $true
        }
    }

    # Check if running as Administrator
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        return $true
    }

    return $false
}

if (-not (Test-SymlinkCapability)) {
    Write-Host "X" -ForegroundColor Red -NoNewline
    Write-Host " Cannot create symlinks. Enable Developer Mode or run as Administrator."
    Write-Host ""
    Write-Host "  To enable Developer Mode:"
    Write-Host "    Settings > Update & Security > For developers > Developer Mode"
    Write-Host ""
    Write-Host "  Or run this script in an elevated PowerShell session."
    exit 1
}

# -- Resolve paths ----------------------------------------------------------

$ScriptDir = $PSScriptRoot
$ConfigDir = Join-Path $env:USERPROFILE ".config\opencode"

# -- State ------------------------------------------------------------------

$Linked = 0
$Skipped = 0

# -- Guard: OpenCode must be installed --------------------------------------

if (-not (Test-Path $ConfigDir -PathType Container)) {
    Write-Host "X" -ForegroundColor Red -NoNewline
    Write-Host " OpenCode config directory not found. Install OpenCode first."
    exit 1
}

# -- Directory name detection -----------------------------------------------
# OpenCode supports both singular (command/) and plural (commands/) directory
# names. We detect which variant exists, falling back to sensible defaults.

function Resolve-ConfigSubdir {
    param(
        [string]$Plural,
        [string]$Singular,
        [string]$Default
    )

    $pluralPath = Join-Path $ConfigDir $Plural
    $singularPath = Join-Path $ConfigDir $Singular

    if (Test-Path $pluralPath -PathType Container) {
        return $pluralPath
    }
    if (Test-Path $singularPath -PathType Container) {
        return $singularPath
    }

    $defaultPath = Join-Path $ConfigDir $Default
    New-Item -Path $defaultPath -ItemType Directory -Force | Out-Null
    return $defaultPath
}

$AgentsDir = Resolve-ConfigSubdir "agents" "agent" "agents"
$SkillsDir = Resolve-ConfigSubdir "skills" "skill" "skills"
$CommandsDir = Resolve-ConfigSubdir "commands" "command" "commands"

# -- Symlink helper ---------------------------------------------------------

function New-Symlink {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Label
    )

    # Source must exist - fail fast on bad repo state
    if (-not (Test-Path $Source)) {
        Write-Host "X" -ForegroundColor Red -NoNewline
        Write-Host " Source not found: $Source"
        return
    }

    # Already a symlink pointing to the correct source - nothing to do
    $targetItem = Get-Item $Target -ErrorAction SilentlyContinue
    if ($targetItem -and ($targetItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        $existingTarget = $targetItem.Target
        # Normalize both paths for reliable comparison
        $normalizedSource = [IO.Path]::GetFullPath($Source)
        $normalizedExisting = if ($existingTarget) { [IO.Path]::GetFullPath($existingTarget) } else { "" }
        if ($normalizedExisting -eq $normalizedSource) {
            Write-Host "  Already linked $Label"
            $script:Skipped++
            return
        }
    }

    # Target exists (file, directory, or different symlink)
    if (Test-Path $Target) {
        if ($Force) {
            Remove-Item $Target -Force -Recurse
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
            Write-Host "  Replaced $Label" -ForegroundColor Yellow
            $script:Linked++
            return
        }
        else {
            Write-Host "->" -ForegroundColor Yellow -NoNewline
            Write-Host " Skipped $Label (already exists, use -Force to replace)"
            $script:Skipped++
            return
        }
    }

    # Happy path: target is free, create the symlink
    New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
    Write-Host "+" -ForegroundColor Green -NoNewline
    Write-Host " Linked $Label"
    $script:Linked++
}

# -- Agents (individual .md files) ------------------------------------------

Write-Host "Agents:"
$agentFiles = Get-ChildItem -Path (Join-Path $ScriptDir "agents") -Filter "*.md" -File
foreach ($file in $agentFiles) {
    $targetPath = Join-Path $AgentsDir $file.Name
    New-Symlink -Source $file.FullName -Target $targetPath -Label $file.Name
}

# -- Skills (entire directories, not individual files) ----------------------

Write-Host ""
Write-Host "Skills:"
$skillDirs = Get-ChildItem -Path (Join-Path $ScriptDir "skills") -Directory
foreach ($dir in $skillDirs) {
    $targetPath = Join-Path $SkillsDir $dir.Name
    New-Symlink -Source $dir.FullName -Target $targetPath -Label $dir.Name
}

# -- Commands (individual .md files) ----------------------------------------

Write-Host ""
Write-Host "Commands:"
$commandFiles = Get-ChildItem -Path (Join-Path $ScriptDir "commands") -Filter "*.md" -File
foreach ($file in $commandFiles) {
    $targetPath = Join-Path $CommandsDir $file.Name
    New-Symlink -Source $file.FullName -Target $targetPath -Label $file.Name
}

# -- Summary ----------------------------------------------------------------

Write-Host ""
Write-Host "Done! $Linked items linked, $Skipped skipped."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Add the MCP server config to your opencode.jsonc"
Write-Host "     See: mcp-config-template.jsonc"
Write-Host "  2. Set your ServiceNow credentials as environment variables"
Write-Host "     See: README.md"
