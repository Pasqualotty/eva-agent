# ============================================================================
# EVA Agent - Windows local-dev bootstrap
# ============================================================================
# Creates a repo-local .venv, installs editable package with minimal extras,
# and verifies `eva --help` (or python -m hermes_cli.main --help).
#
# Usage (from repo root or any cwd):
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\bootstrap_dev.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\bootstrap_dev.ps1 -Extras "cli,mcp"
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\bootstrap_dev.ps1 -Recreate
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\bootstrap_dev.ps1 -SkipVerify
#
# Exit codes:
#   0 - venv ready and CLI help works (or -SkipVerify and install succeeded)
#   1 - missing Python / install failed / help verification failed
#   2 - could not locate repo root
#
# Notes:
#   - Does NOT commit .venv (gitignored).
#   - Does NOT require admin.
#   - Prefer uv when available; falls back to stdlib venv + pip.
#   - Default extras: cli (simple-term-menu). Core deps come from pyproject.
#   - Keep this file ASCII-only for Windows PowerShell 5.1 parser safety.
# ============================================================================

[CmdletBinding()]
param(
    # Comma-separated extras, e.g. "cli" or "cli,mcp,web". Empty = base only.
    [string]$Extras = "cli",
    # Force delete and recreate .venv
    [switch]$Recreate,
    # Install only; skip eva --help check
    [switch]$SkipVerify,
    # Also set User-level HERMES_HOME / EVA_HOME to %LOCALAPPDATA%\eva
    [switch]$SetUserEnv,
    # Prefer pip even when uv is on PATH
    [switch]$NoUv
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

# --- Resolve repo root -------------------------------------------------------
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
$repoRoot = Split-Path -Parent $scriptDir

function Test-RepoRoot {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($m in @("pyproject.toml", "hermes_constants.py", "hermes_cli", "toolsets.py")) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path $m))) { return $false }
    }
    return $true
}

if (-not (Test-RepoRoot $repoRoot)) {
    $probe = (Get-Location).Path
    $found = $null
    for ($i = 0; $i -lt 6; $i++) {
        if (Test-RepoRoot $probe) { $found = $probe; break }
        $parent = Split-Path -Parent $probe
        if (-not $parent -or $parent -eq $probe) { break }
        $probe = $parent
    }
    if ($found) {
        $repoRoot = $found
    } else {
        Write-Fail "Could not locate EVA repo root (need pyproject.toml + hermes_constants.py + hermes_cli)."
        exit 2
    }
}

Set-Location -LiteralPath $repoRoot
$venvDir = Join-Path $repoRoot ".venv"
$venvPy  = Join-Path $venvDir "Scripts\python.exe"
$venvEva = Join-Path $venvDir "Scripts\eva.exe"
$venvHermes = Join-Path $venvDir "Scripts\hermes.exe"

Write-Host ""
Write-Host "EVA Agent - Windows local bootstrap" -ForegroundColor Cyan
Write-Host ("  repo:  {0}" -f $repoRoot)
Write-Host ("  venv:  {0}" -f $venvDir)
Write-Host ""

# --- Find Python 3.11-3.13 ---------------------------------------------------
function Find-Python {
    $candidates = New-Object System.Collections.ArrayList

    $pyLauncher = Get-Command "py" -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        foreach ($spec in @("-3.12", "-3.11", "-3.13", "-3")) {
            try {
                $via = & py $spec -c "import sys; print(sys.executable)" 2>$null
                if ($LASTEXITCODE -eq 0 -and $via) {
                    [void]$candidates.Add($via.Trim())
                }
            } catch { }
        }
    }

    foreach ($cmd in @("python3", "python")) {
        $info = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($info -and $info.Source) {
            [void]$candidates.Add($info.Source)
        }
    }

    foreach ($exe in $candidates) {
        if (-not $exe) { continue }
        if ($exe -match 'WindowsApps\\python') { continue }
        try {
            $code = @'
import sys
v = sys.version_info
ok = v >= (3, 11) and v < (3, 14)
print("%d.%d.%d" % v[:3])
sys.exit(0 if ok else 1)
'@
            $tmp = [System.IO.Path]::GetTempFileName() + ".py"
            try {
                [System.IO.File]::WriteAllText($tmp, $code, (New-Object System.Text.UTF8Encoding $false))
                $ver = & $exe $tmp 2>$null
                if ($LASTEXITCODE -eq 0 -and $ver) {
                    return @{ Exe = $exe; Version = $ver.Trim() }
                }
            } finally {
                Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
            }
        } catch {
            continue
        }
    }
    return $null
}

Write-Info "Looking for Python >=3.11,<3.14..."
$py = Find-Python
if ($null -eq $py) {
    Write-Fail "No usable Python 3.11-3.13 on PATH."
    Write-Host ""
    Write-Host "Install one of:" -ForegroundColor Yellow
    Write-Host "  - https://www.python.org/downloads/ (check 'Add python.exe to PATH')"
    Write-Host "  - winget install Python.Python.3.12"
    Write-Host "  - Or use the full installer: iex (irm https://raw.githubusercontent.com/Pasqualotty/eva-agent/main/scripts/install.ps1)"
    Write-Host ""
    Write-Host "Skip note: bootstrap cannot create a venv without a system Python in range."
    exit 1
}
Write-Ok ("Python {0} ({1})" -f $py.Version, $py.Exe)

# --- Optional: session + user home ------------------------------------------
$defaultHome = Join-Path $env:LOCALAPPDATA "eva"
if (-not $env:HERMES_HOME -and -not $env:EVA_HOME) {
    $env:HERMES_HOME = $defaultHome
    $env:EVA_HOME = $defaultHome
    Write-Info ("Session EVA_HOME/HERMES_HOME -> {0}" -f $defaultHome)
} else {
    if ($env:EVA_HOME) {
        Write-Info ("EVA_HOME already set -> {0}" -f $env:EVA_HOME)
    } else {
        Write-Info ("HERMES_HOME already set -> {0}" -f $env:HERMES_HOME)
    }
}

if ($SetUserEnv) {
    [Environment]::SetEnvironmentVariable("HERMES_HOME", $defaultHome, "User")
    [Environment]::SetEnvironmentVariable("EVA_HOME", $defaultHome, "User")
    Write-Ok ("User env EVA_HOME/HERMES_HOME = {0}" -f $defaultHome)
}

if (-not (Test-Path -LiteralPath $defaultHome)) {
    New-Item -ItemType Directory -Path $defaultHome -Force | Out-Null
    Write-Ok ("Created data home {0}" -f $defaultHome)
}

# --- Create / recreate venv --------------------------------------------------
$uvCmd = $null
if (-not $NoUv) {
    $uvInfo = Get-Command "uv" -ErrorAction SilentlyContinue
    if ($uvInfo) {
        $uvCmd = $uvInfo.Source
    } elseif (Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA "eva\bin\uv.exe")) {
        $uvCmd = Join-Path $env:LOCALAPPDATA "eva\bin\uv.exe"
    } elseif (Test-Path -LiteralPath (Join-Path $env:USERPROFILE ".local\bin\uv.exe")) {
        $uvCmd = Join-Path $env:USERPROFILE ".local\bin\uv.exe"
    } elseif (Test-Path -LiteralPath (Join-Path $env:USERPROFILE ".cargo\bin\uv.exe")) {
        $uvCmd = Join-Path $env:USERPROFILE ".cargo\bin\uv.exe"
    }
}

if ($Recreate -and (Test-Path -LiteralPath $venvDir)) {
    Write-Info "Removing existing .venv (-Recreate)..."
    Remove-Item -LiteralPath $venvDir -Recurse -Force
}

if (-not (Test-Path -LiteralPath $venvPy)) {
    Write-Info "Creating .venv..."
    if ($uvCmd) {
        & $uvCmd venv $venvDir --python $py.Exe
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "uv venv failed; falling back to python -m venv"
            & $py.Exe -m venv $venvDir
        }
    } else {
        & $py.Exe -m venv $venvDir
    }
    if (-not (Test-Path -LiteralPath $venvPy)) {
        Write-Fail "Failed to create .venv at $venvDir"
        exit 1
    }
    Write-Ok ".venv created"
} else {
    Write-Ok ".venv already present (use -Recreate to rebuild)"
}

# --- Install editable package ------------------------------------------------
$extraSpec = ""
if ($Extras -and $Extras.Trim()) {
    # Normalize: "cli, mcp" -> "cli,mcp"
    $parts = $Extras.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if ($parts.Count -gt 0) {
        $extraSpec = ".[{0}]" -f ($parts -join ",")
    } else {
        $extraSpec = "."
    }
} else {
    $extraSpec = "."
}

Write-Info ("Installing editable package: pip/uv install -e `"{0}`"" -f $extraSpec)

$installOk = $false
if ($uvCmd) {
    Write-Info ("Using uv ({0})" -f $uvCmd)
    # uv pip install into the venv
    & $uvCmd pip install --python $venvPy -e $extraSpec
    if ($LASTEXITCODE -eq 0) {
        $installOk = $true
    } else {
        Write-Warn "uv pip install failed (exit $LASTEXITCODE); trying python -m pip"
    }
}

if (-not $installOk) {
    Write-Info "Bootstrapping pip in venv..."
    & $venvPy -m ensurepip --upgrade 2>$null | Out-Null
    & $venvPy -m pip install --upgrade pip setuptools wheel
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "pip upgrade failed"
        exit 1
    }
    & $venvPy -m pip install -e $extraSpec
    if ($LASTEXITCODE -ne 0) {
        Write-Fail ("pip install -e {0} failed" -f $extraSpec)
        Write-Host ""
        Write-Host "Common fixes:" -ForegroundColor Yellow
        Write-Host "  - Network / proxy: configure pip index or retry"
        Write-Host "  - Build tools: install Visual C++ Build Tools if a wheel is missing"
        Write-Host "  - Try fewer extras: -Extras ''   or   -Extras cli"
        Write-Host "  - Full managed install: scripts\install.ps1"
        exit 1
    }
    $installOk = $true
}
Write-Ok ("Installed -e {0}" -f $extraSpec)

# --- Verify CLI --------------------------------------------------------------
function Test-CliHelp {
    param(
        [string]$Label,
        [string[]]$Command
    )
    Write-Info ("Verify: {0}" -f $Label)
    try {
        $cmdExe = $Command[0]
        $cmdArgs = @()
        if ($Command.Length -gt 1) {
            $cmdArgs = $Command[1..($Command.Length - 1)]
        }
        $out = & $cmdExe @cmdArgs 2>&1
        $code = $LASTEXITCODE
        $text = ($out | Out-String)
        if ($code -eq 0) {
            Write-Ok ("{0} (exit 0)" -f $Label)
            return $true
        }
        # Some CLIs print help but exit non-zero; accept if usage-like text present
        if ($text -match "(?i)(usage:|commands:|options:|eva|hermes)") {
            Write-Ok ("{0} (help text present, exit {1})" -f $Label, $code)
            return $true
        }
        Write-Fail ("{0} failed (exit {1})" -f $Label, $code)
        if ($text) {
            $snippet = $text.Substring(0, [Math]::Min(400, $text.Length))
            Write-Host $snippet -ForegroundColor DarkGray
        }
        return $false
    } catch {
        Write-Fail ("{0}: {1}" -f $Label, $_.Exception.Message)
        return $false
    }
}

$verifyOk = $true
if (-not $SkipVerify) {
    $any = $false
    if (Test-Path -LiteralPath $venvEva) {
        if (Test-CliHelp -Label "eva --help" -Command @($venvEva, "--help")) {
            $any = $true
        } else {
            $verifyOk = $false
        }
    } elseif (Test-Path -LiteralPath $venvHermes) {
        Write-Warn "eva.exe not found in venv; trying hermes.exe + module"
        if (Test-CliHelp -Label "hermes --help" -Command @($venvHermes, "--help")) {
            $any = $true
        }
    }

    if (-not $any) {
        if (Test-CliHelp -Label "python -m hermes_cli.main --help" -Command @($venvPy, "-m", "hermes_cli.main", "--help")) {
            $any = $true
        } else {
            $verifyOk = $false
        }
    }

    if (-not $any) {
        $verifyOk = $false
        Write-Fail "Could not run CLI help via eva, hermes, or python -m hermes_cli.main"
    }
} else {
    Write-Warn "Skipping CLI verify (-SkipVerify)"
}

# --- Summary -----------------------------------------------------------------
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
if ($verifyOk) {
    Write-Ok "Bootstrap complete"
} else {
    Write-Fail "Bootstrap finished with verify failures"
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Activate the venv in this shell:"
Write-Host ("       .\.venv\Scripts\Activate.ps1") -ForegroundColor White
Write-Host "  2. Run the CLI:"
Write-Host ("       eva --help") -ForegroundColor White
Write-Host ("       eva setup") -ForegroundColor White
Write-Host ("       eva") -ForegroundColor White
Write-Host "  3. Or call without activating:"
Write-Host ("       .\.venv\Scripts\eva.exe --help") -ForegroundColor White
Write-Host ("       .\.venv\Scripts\python.exe -m hermes_cli.main --help") -ForegroundColor White
Write-Host ""
Write-Host ("Data home (config / .env): {0}" -f $(if ($env:EVA_HOME) { $env:EVA_HOME } elseif ($env:HERMES_HOME) { $env:HERMES_HOME } else { $defaultHome }))
Write-Host "Full user install (PATH + managed tools): scripts\install.ps1"
Write-Host "Docs: docs\install-windows.md"
Write-Host ""

if ($verifyOk) { exit 0 } else { exit 1 }
