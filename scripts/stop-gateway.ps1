# ============================================================================
# EVA Agent - stop messaging gateway (Windows)
# ============================================================================
# Stops the background gateway process for the current EVA home profile.
# Does not touch git; does not read or print secrets.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\stop-gateway.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\stop-gateway.ps1 -StatusAfter
#
# Exit codes:
#   0 - stop command completed (even if nothing was running)
#   1 - CLI not found or stop failed hard
#
# Keep this file ASCII-only for Windows PowerShell 5.1 parser safety.
# ============================================================================

[CmdletBinding()]
param(
    [switch]$StatusAfter
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
} catch { }

function Write-Info  { param([string]$m) Write-Host ("-> {0}" -f $m) -ForegroundColor Cyan }
function Write-Ok    { param([string]$m) Write-Host ("[OK] {0}" -f $m) -ForegroundColor Green }
function Write-Warn  { param([string]$m) Write-Host ("[WARN] {0}" -f $m) -ForegroundColor Yellow }
function Write-Fail  { param([string]$m) Write-Host ("[FAIL] {0}" -f $m) -ForegroundColor Red }

function Get-EvaHome {
    if ($env:EVA_HOME -and $env:EVA_HOME.Trim()) {
        return $env:EVA_HOME.Trim().TrimEnd('\', '/')
    }
    if ($env:HERMES_HOME -and $env:HERMES_HOME.Trim()) {
        return $env:HERMES_HOME.Trim().TrimEnd('\', '/')
    }
    if ($env:LOCALAPPDATA) {
        return (Join-Path $env:LOCALAPPDATA "eva")
    }
    return (Join-Path $env:USERPROFILE ".eva")
}

function Resolve-RepoRoot {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    $candidate = Split-Path -Parent $scriptDir
    $markers = @("pyproject.toml", "hermes_constants.py", "hermes_cli")
    $ok = $true
    foreach ($m in $markers) {
        if (-not (Test-Path -LiteralPath (Join-Path $candidate $m))) { $ok = $false; break }
    }
    if ($ok) { return $candidate }
    return $null
}

function Find-EvaCommand {
    param([string]$RepoRoot)

    $cmd = Get-Command "eva" -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return @{ Kind = "exe"; Path = $cmd.Source; ArgsPrefix = @() }
    }
    $cmdH = Get-Command "hermes" -ErrorAction SilentlyContinue
    if ($cmdH -and $cmdH.Source) {
        return @{ Kind = "exe"; Path = $cmdH.Source; ArgsPrefix = @() }
    }

    $managed = Join-Path (Get-EvaHome) "eva-agent\.venv\Scripts\eva.exe"
    if (Test-Path -LiteralPath $managed) {
        return @{ Kind = "exe"; Path = $managed; ArgsPrefix = @() }
    }
    $managedH = Join-Path (Get-EvaHome) "eva-agent\.venv\Scripts\hermes.exe"
    if (Test-Path -LiteralPath $managedH) {
        return @{ Kind = "exe"; Path = $managedH; ArgsPrefix = @() }
    }

    if ($RepoRoot) {
        $venvEva = Join-Path $RepoRoot ".venv\Scripts\eva.exe"
        if (Test-Path -LiteralPath $venvEva) {
            return @{ Kind = "exe"; Path = $venvEva; ArgsPrefix = @() }
        }
        $venvHermes = Join-Path $RepoRoot ".venv\Scripts\hermes.exe"
        if (Test-Path -LiteralPath $venvHermes) {
            return @{ Kind = "exe"; Path = $venvHermes; ArgsPrefix = @() }
        }
        $venvPy = Join-Path $RepoRoot ".venv\Scripts\python.exe"
        if (Test-Path -LiteralPath $venvPy) {
            return @{
                Kind       = "py"
                Path       = $venvPy
                ArgsPrefix = @("-m", "hermes_cli.main")
            }
        }
    }

    $py = Get-Command "python" -ErrorAction SilentlyContinue
    if ($py -and $RepoRoot) {
        return @{
            Kind       = "py"
            Path       = $py.Source
            ArgsPrefix = @("-m", "hermes_cli.main")
            WorkDir    = $RepoRoot
        }
    }

    return $null
}

function Invoke-Eva {
    param(
        [Parameter(Mandatory = $true)]$Eva,
        [Parameter(Mandatory = $true)][string[]]$GatewayArgs
    )
    $argList = @()
    if ($Eva.ArgsPrefix) { $argList += $Eva.ArgsPrefix }
    $argList += $GatewayArgs
    $wd = $null
    if ($Eva.WorkDir) { $wd = $Eva.WorkDir }

    # Stream CLI output to host; return ONLY the integer exit code.
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $code = 0
    try {
        if ($wd) { Push-Location -LiteralPath $wd }
        $lines = & $Eva.Path @argList 2>&1
        if ($null -ne $LASTEXITCODE) { $code = [int]$LASTEXITCODE }
        foreach ($line in @($lines)) {
            if ($null -eq $line) { continue }
            Write-Host ([string]$line)
        }
    } finally {
        if ($wd) { Pop-Location }
        $ErrorActionPreference = $oldEap
    }
    return ,$code
}

# --- main --------------------------------------------------------------------

$evaHome = Get-EvaHome
$repoRoot = Resolve-RepoRoot
$env:EVA_HOME = $evaHome
$env:HERMES_HOME = $evaHome
$env:HERMES_NONINTERACTIVE = "1"

Write-Host ""
Write-Host "EVA Agent - stop gateway (Windows)" -ForegroundColor Cyan
Write-Host ("  home: {0}" -f $evaHome)
Write-Host ""

$eva = Find-EvaCommand -RepoRoot $repoRoot
if (-not $eva) {
    Write-Fail "CLI 'eva' (ou hermes) nao encontrada."
    Write-Host "  Bootstrap: powershell -File scripts\bootstrap_dev.ps1"
    exit 1
}
Write-Ok ("CLI: {0}" -f $eva.Path)

Write-Info "Doctor pre-stop: eva gateway status"
try {
    $null = Invoke-Eva -Eva $eva -GatewayArgs @("gateway", "status")
} catch {
    Write-Warn ("status: {0}" -f $_.Exception.Message)
}

Write-Info "Parando gateway..."
$code = 0
try {
    $code = Invoke-Eva -Eva $eva -GatewayArgs @("gateway", "stop")
} catch {
    Write-Fail ("gateway stop falhou: {0}" -f $_.Exception.Message)
    exit 1
}

if ($code -ne 0) {
    Write-Warn ("gateway stop exit={0}" -f $code)
} else {
    Write-Ok "gateway stop acionado"
}

if ($StatusAfter) {
    Write-Info "Doctor pos-stop: eva gateway status"
    try {
        $null = Invoke-Eva -Eva $eva -GatewayArgs @("gateway", "status")
    } catch {
        Write-Warn ("status: {0}" -f $_.Exception.Message)
    }
}

Write-Host ""
Write-Host "Para subir de novo:" -ForegroundColor Cyan
Write-Host "  powershell -File scripts\start-gateway.ps1"
Write-Host ""
exit 0
