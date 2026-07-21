# ============================================================================
# EVA Agent - permanent user PATH (Windows, no admin)
# ============================================================================
# Puts `eva` / `hermes` on the *user* PATH without requiring .venv activation
# every session. Prefer a dedicated venv under %LOCALAPPDATA%\eva\venv and
# thin .cmd shims under %LOCALAPPDATA%\eva\shims (only that dir hits PATH).
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install-user-path.ps1 -DryRun
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install-user-path.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install-user-path.ps1 -UserPip
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install-user-path.ps1 -SkipInstall
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install-user-path.ps1 -Remove
#
# Exit codes:
#   0 - success (or dry-run completed)
#   1 - missing Python / install failed / verify failed
#   2 - could not locate repo when install was required
#
# Notes:
#   - No admin. Only User env (PATH, EVA_HOME, HERMES_HOME).
#   - Does NOT commit any venv (lives under %LOCALAPPDATA%\eva, outside git).
#   - -DryRun never writes files or registry/env.
#   - Keep this file ASCII-only for Windows PowerShell 5.1 parser safety.
# ============================================================================

[CmdletBinding()]
param(
    # Preview only: print plan, no env/file writes
    [switch]$DryRun,
    # Use `pip install --user` instead of a dedicated venv
    [switch]$UserPip,
    # Only wire shims + PATH + EVA_HOME; do not create venv / pip install
    [switch]$SkipInstall,
    # Remove shims dir from user PATH and delete generated shims (keep venv)
    [switch]$Remove,
    # Also remove EVA_HOME / HERMES_HOME user env when -Remove
    [switch]$RemoveHomeEnv,
    # Install editable package from this checkout (default: parent of scripts/)
    [string]$SourceRepo = "",
    # Data home (product default)
    [string]$EvaHome = "",
    # Where the managed venv lives (ignored with -UserPip)
    [string]$VenvDir = "",
    # Directory that holds eva.cmd / hermes.cmd and is added to user PATH
    [string]$ShimsDir = "",
    # pip extras when installing (venv or --user). Empty = base only.
    [string]$Extras = "cli",
    # Prefer stdlib venv + pip even when uv is on PATH
    [switch]$NoUv,
    # Skip post-install `eva --help` / python -m check
    [switch]$SkipVerify
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
function Write-Plan  { param([string]$m) Write-Host ("[DRY] {0}" -f $m) -ForegroundColor Magenta }

# --- Resolve defaults --------------------------------------------------------
if (-not $EvaHome) {
    if ($env:EVA_HOME) { $EvaHome = $env:EVA_HOME }
    elseif ($env:HERMES_HOME) { $EvaHome = $env:HERMES_HOME }
    else { $EvaHome = Join-Path $env:LOCALAPPDATA "eva" }
}
if (-not $VenvDir)  { $VenvDir  = Join-Path $EvaHome "venv" }
if (-not $ShimsDir) { $ShimsDir = Join-Path $EvaHome "shims" }

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Test-RepoRoot {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($m in @("pyproject.toml", "hermes_constants.py", "hermes_cli", "toolsets.py")) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path $m))) { return $false }
    }
    return $true
}

function Resolve-RepoRoot {
    param([string]$Hint)
    if ($Hint -and (Test-RepoRoot $Hint)) { return (Resolve-Path -LiteralPath $Hint).Path }

    $candidates = New-Object System.Collections.ArrayList
    $fromScript = Split-Path -Parent $scriptDir
    [void]$candidates.Add($fromScript)
    [void]$candidates.Add((Get-Location).Path)
    $managed = Join-Path $EvaHome "eva-agent"
    [void]$candidates.Add($managed)

    foreach ($c in $candidates) {
        if (Test-RepoRoot $c) { return (Resolve-Path -LiteralPath $c).Path }
    }

    # Walk up from cwd a few levels
    $probe = (Get-Location).Path
    for ($i = 0; $i -lt 6; $i++) {
        if (Test-RepoRoot $probe) { return $probe }
        $parent = Split-Path -Parent $probe
        if (-not $parent -or $parent -eq $probe) { break }
        $probe = $parent
    }
    return $null
}

function Get-UserPathEntries {
    $raw = [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $raw) { return @() }
    return @($raw.Split(';') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Test-PathHasDir {
    param([string]$Dir)
    $norm = $Dir.TrimEnd('\')
    foreach ($e in (Get-UserPathEntries)) {
        if ($e.TrimEnd('\') -ieq $norm) { return $true }
    }
    return $false
}

function Add-UserPathDir {
    param([string]$Dir)
    if (Test-PathHasDir $Dir) {
        Write-Info ("User PATH already contains: {0}" -f $Dir)
        return $false
    }
    $entries = Get-UserPathEntries
    $newPath = ($Dir + ";" + ($entries -join ";")).TrimEnd(';')
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $Dir + ";" + $env:Path
    Write-Ok ("Added to user PATH: {0}" -f $Dir)
    return $true
}

function Remove-UserPathDir {
    param([string]$Dir)
    $norm = $Dir.TrimEnd('\')
    $entries = @(Get-UserPathEntries | Where-Object { $_.TrimEnd('\') -ine $norm })
    $newPath = $entries -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    # Best-effort session refresh (cannot fully rebuild process PATH safely)
    $env:Path = ($env:Path.Split(';') | Where-Object { $_.TrimEnd('\') -ine $norm }) -join ";"
    Write-Ok ("Removed from user PATH: {0}" -f $Dir)
}

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
        if ($info -and $info.Source) { [void]$candidates.Add($info.Source) }
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
        } catch { continue }
    }
    return $null
}

function Find-Uv {
    if ($NoUv) { return $null }
    $uvInfo = Get-Command "uv" -ErrorAction SilentlyContinue
    if ($uvInfo) { return $uvInfo.Source }
    foreach ($p in @(
        (Join-Path $env:LOCALAPPDATA "eva\bin\uv.exe"),
        (Join-Path $env:USERPROFILE ".local\bin\uv.exe"),
        (Join-Path $env:USERPROFILE ".cargo\bin\uv.exe")
    )) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

function Get-ExtraSpec {
    if ($Extras -and $Extras.Trim()) {
        $parts = $Extras.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        if ($parts.Count -gt 0) { return ".[{0}]" -f ($parts -join ",") }
    }
    return "."
}

function New-CmdShim {
    param(
        [string]$Path,
        [string]$TargetExe,
        [string]$ModuleFallback,  # e.g. hermes_cli.main when TargetExe missing
        [string]$PythonExe,
        [string]$HomePath
    )
    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add("@echo off")
    [void]$lines.Add("REM Generated by scripts/install-user-path.ps1 - do not edit by hand")
    [void]$lines.Add(("set `"EVA_HOME={0}`"" -f $HomePath))
    [void]$lines.Add("if not defined HERMES_HOME set `"HERMES_HOME=%EVA_HOME%`"")
    if ($TargetExe -and (Test-Path -LiteralPath $TargetExe)) {
        [void]$lines.Add(("`"{0}`" %*" -f $TargetExe))
    } elseif ($PythonExe -and $ModuleFallback) {
        [void]$lines.Add(("`"{0}`" -m {1} %*" -f $PythonExe, $ModuleFallback))
    } else {
        throw ("Cannot write shim {0}: no target exe and no python/module fallback" -f $Path)
    }
    $text = ($lines -join "`r`n") + "`r`n"
    [System.IO.File]::WriteAllText($Path, $text, (New-Object System.Text.UTF8Encoding $false))
}

function Get-UserSiteScripts {
    param([string]$PythonExe)
    try {
        $out = & $PythonExe -c "import site,sys; print(site.getusersitepackages())" 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $out) { return $null }
        $site = $out.Trim()
        # Scripts live next to site-packages on Windows: ...\Python311\Scripts or Roaming\Python\Python311\Scripts
        $scripts = Join-Path (Split-Path -Parent $site) "Scripts"
        if (Test-Path -LiteralPath $scripts) { return $scripts }
        # Alternate layout: site is ...\site-packages, Scripts is sibling of that parent
        $alt = Join-Path (Split-Path -Parent (Split-Path -Parent $site)) "Scripts"
        if (Test-Path -LiteralPath $alt) { return $alt }
        return $scripts
    } catch {
        return $null
    }
}

# --- Banner ------------------------------------------------------------------
Write-Host ""
Write-Host "EVA Agent - user PATH install (Windows)" -ForegroundColor Cyan
Write-Host ("  EVA_HOME : {0}" -f $EvaHome)
Write-Host ("  Shims    : {0}" -f $ShimsDir)
if ($UserPip) {
    Write-Host "  Mode     : pip install --user + shims"
} else {
    Write-Host ("  Venv     : {0}" -f $VenvDir)
}
if ($DryRun) {
    Write-Host "  Mode     : DRY-RUN (no writes)" -ForegroundColor Magenta
}
Write-Host ""

# --- Remove mode -------------------------------------------------------------
if ($Remove) {
    if ($DryRun) {
        Write-Plan ("Would remove shims dir from user PATH if present: {0}" -f $ShimsDir)
        Write-Plan ("Would delete: {0}\eva.cmd, hermes.cmd" -f $ShimsDir)
        if ($RemoveHomeEnv) {
            Write-Plan "Would clear user env EVA_HOME / HERMES_HOME if they match this EvaHome"
        }
        Write-Ok "Dry-run remove plan complete"
        exit 0
    }
    if (Test-PathHasDir $ShimsDir) {
        Remove-UserPathDir -Dir $ShimsDir
    } else {
        Write-Info "Shims dir not on user PATH (nothing to remove)"
    }
    foreach ($name in @("eva.cmd", "hermes.cmd")) {
        $p = Join-Path $ShimsDir $name
        if (Test-Path -LiteralPath $p) {
            Remove-Item -LiteralPath $p -Force
            Write-Ok ("Deleted {0}" -f $p)
        }
    }
    if ($RemoveHomeEnv) {
        $curE = [Environment]::GetEnvironmentVariable("EVA_HOME", "User")
        $curH = [Environment]::GetEnvironmentVariable("HERMES_HOME", "User")
        if ($curE -and ($curE.TrimEnd('\') -ieq $EvaHome.TrimEnd('\'))) {
            [Environment]::SetEnvironmentVariable("EVA_HOME", $null, "User")
            Write-Ok "Cleared user EVA_HOME"
        }
        if ($curH -and ($curH.TrimEnd('\') -ieq $EvaHome.TrimEnd('\'))) {
            [Environment]::SetEnvironmentVariable("HERMES_HOME", $null, "User")
            Write-Ok "Cleared user HERMES_HOME"
        }
    }
    Write-Ok "Remove complete (venv under EvaHome left intact if present)"
    exit 0
}

# --- Resolve install target --------------------------------------------------
$repoRoot = Resolve-RepoRoot -Hint $SourceRepo
$extraSpec = Get-ExtraSpec

$plan = New-Object System.Collections.Generic.List[string]
[void]$plan.Add("Ensure data home directory: $EvaHome")
[void]$plan.Add("Set user env EVA_HOME=$EvaHome (and HERMES_HOME alias)")
[void]$plan.Add("Create shims directory: $ShimsDir")
[void]$plan.Add("Write shims: eva.cmd, hermes.cmd")
[void]$plan.Add("Prepend shims dir to user PATH (if missing)")

if (-not $SkipInstall) {
    if ($UserPip) {
        [void]$plan.Add("pip install --user -e `"$extraSpec`" from repo (or fail if no repo)")
    } else {
        [void]$plan.Add("Create/reuse venv at $VenvDir")
        [void]$plan.Add("pip/uv install -e `"$extraSpec`" into that venv")
    }
} else {
    [void]$plan.Add("Skip package install (-SkipInstall); shims point at existing entry if found")
}

if (-not $SkipVerify) {
    [void]$plan.Add("Verify: shim or python -m hermes_cli.main --help")
}

Write-Info "Plan:"
foreach ($step in $plan) {
    if ($DryRun) { Write-Plan $step } else { Write-Host ("   - {0}" -f $step) }
}
Write-Host ""

if ($DryRun) {
    Write-Info "Current user PATH has shims dir: $(Test-PathHasDir $ShimsDir)"
    $ue = [Environment]::GetEnvironmentVariable("EVA_HOME", "User")
    $uh = [Environment]::GetEnvironmentVariable("HERMES_HOME", "User")
    Write-Info ("Current user EVA_HOME   : {0}" -f $(if ($ue) { $ue } else { "(unset)" }))
    Write-Info ("Current user HERMES_HOME: {0}" -f $(if ($uh) { $uh } else { "(unset)" }))
    Write-Info ("Repo root resolved      : {0}" -f $(if ($repoRoot) { $repoRoot } else { "(none)" }))
    $pyProbe = Find-Python
    if ($pyProbe) {
        Write-Ok ("Python available         : {0} ({1})" -f $pyProbe.Version, $pyProbe.Exe)
    } else {
        Write-Warn "No Python 3.11-3.13 on PATH (full install would fail without -SkipInstall)"
    }
    if (-not $SkipInstall -and -not $repoRoot) {
        Write-Warn "No SourceRepo / checkout found; full install would need -SourceRepo or -SkipInstall"
    }
    Write-Host ""
    Write-Ok "Dry-run complete (no changes written)"
    Write-Host "Run without -DryRun to apply. Open a NEW terminal after apply for PATH."
    exit 0
}

# --- Apply: data home --------------------------------------------------------
if (-not (Test-Path -LiteralPath $EvaHome)) {
    New-Item -ItemType Directory -Path $EvaHome -Force | Out-Null
    Write-Ok ("Created {0}" -f $EvaHome)
} else {
    Write-Info ("Data home exists: {0}" -f $EvaHome)
}

[Environment]::SetEnvironmentVariable("EVA_HOME", $EvaHome, "User")
[Environment]::SetEnvironmentVariable("HERMES_HOME", $EvaHome, "User")
$env:EVA_HOME = $EvaHome
$env:HERMES_HOME = $EvaHome
Write-Ok ("User env EVA_HOME/HERMES_HOME = {0}" -f $EvaHome)

# --- Install package ---------------------------------------------------------
$pythonForShim = $null
$evaTarget = $null
$hermesTarget = $null

if (-not $SkipInstall) {
    if (-not $repoRoot) {
        Write-Fail "Could not locate EVA checkout (need pyproject.toml + hermes_constants.py)."
        Write-Host "Pass -SourceRepo C:\path\to\eva-agent  or  -SkipInstall if already installed."
        exit 2
    }
    Write-Info ("Source repo: {0}" -f $repoRoot)

    $py = Find-Python
    if ($null -eq $py) {
        Write-Fail "No usable Python 3.11-3.13 on PATH."
        Write-Host "Install Python from https://www.python.org/downloads/ (Add to PATH),"
        Write-Host "or winget install Python.Python.3.12"
        Write-Host "Or use the full installer: scripts\install.ps1"
        exit 1
    }
    Write-Ok ("Python {0} ({1})" -f $py.Version, $py.Exe)

    $uvCmd = Find-Uv
    Push-Location -LiteralPath $repoRoot
    try {
        if ($UserPip) {
            Write-Info ("pip install --user -e {0}" -f $extraSpec)
            & $py.Exe -m pip install --user -e $extraSpec
            if ($LASTEXITCODE -ne 0) {
                Write-Fail "pip install --user failed"
                exit 1
            }
            $pythonForShim = $py.Exe
            $userScripts = Get-UserSiteScripts -PythonExe $py.Exe
            if ($userScripts) {
                $candEva = Join-Path $userScripts "eva.exe"
                $candHermes = Join-Path $userScripts "hermes.exe"
                if (Test-Path -LiteralPath $candEva) { $evaTarget = $candEva }
                if (Test-Path -LiteralPath $candHermes) { $hermesTarget = $candHermes }
            }
            Write-Ok "User site package installed"
        } else {
            $venvPy = Join-Path $VenvDir "Scripts\python.exe"
            if (-not (Test-Path -LiteralPath $venvPy)) {
                Write-Info ("Creating venv: {0}" -f $VenvDir)
                if ($uvCmd) {
                    & $uvCmd venv $VenvDir --python $py.Exe
                    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $venvPy)) {
                        Write-Warn "uv venv failed; falling back to python -m venv"
                        & $py.Exe -m venv $VenvDir
                    }
                } else {
                    & $py.Exe -m venv $VenvDir
                }
                if (-not (Test-Path -LiteralPath $venvPy)) {
                    Write-Fail "Failed to create venv at $VenvDir"
                    exit 1
                }
                Write-Ok "venv created"
            } else {
                Write-Ok "venv already present"
            }

            $installOk = $false
            if ($uvCmd) {
                Write-Info ("uv pip install -e {0}" -f $extraSpec)
                & $uvCmd pip install --python $venvPy -e $extraSpec
                if ($LASTEXITCODE -eq 0) { $installOk = $true }
                else { Write-Warn "uv pip failed; trying python -m pip" }
            }
            if (-not $installOk) {
                & $venvPy -m ensurepip --upgrade 2>$null | Out-Null
                & $venvPy -m pip install --upgrade pip setuptools wheel
                if ($LASTEXITCODE -ne 0) {
                    Write-Fail "pip upgrade failed"
                    exit 1
                }
                & $venvPy -m pip install -e $extraSpec
                if ($LASTEXITCODE -ne 0) {
                    Write-Fail ("pip install -e {0} failed" -f $extraSpec)
                    exit 1
                }
            }
            Write-Ok ("Installed -e {0} into venv" -f $extraSpec)
            $pythonForShim = $venvPy
            $candEva = Join-Path $VenvDir "Scripts\eva.exe"
            $candHermes = Join-Path $VenvDir "Scripts\hermes.exe"
            if (Test-Path -LiteralPath $candEva) { $evaTarget = $candEva }
            if (Test-Path -LiteralPath $candHermes) { $hermesTarget = $candHermes }
        }
    } finally {
        Pop-Location
    }
} else {
    # -SkipInstall: discover existing entry points
    Write-Info "SkipInstall: locating existing eva/hermes entry points"
    $search = @(
        (Join-Path $VenvDir "Scripts"),
        (Join-Path $EvaHome "eva-agent\venv\Scripts"),
        (Join-Path $EvaHome "eva-agent\.venv\Scripts")
    )
    if ($repoRoot) {
        $search += (Join-Path $repoRoot ".venv\Scripts")
        $search += (Join-Path $repoRoot "venv\Scripts")
    }
    foreach ($s in $search) {
        if (-not (Test-Path -LiteralPath $s)) { continue }
        $e = Join-Path $s "eva.exe"
        $h = Join-Path $s "hermes.exe"
        $p = Join-Path $s "python.exe"
        if (-not $evaTarget -and (Test-Path -LiteralPath $e)) { $evaTarget = $e }
        if (-not $hermesTarget -and (Test-Path -LiteralPath $h)) { $hermesTarget = $h }
        if (-not $pythonForShim -and (Test-Path -LiteralPath $p)) { $pythonForShim = $p }
    }
    if (-not $pythonForShim -and -not $evaTarget -and -not $hermesTarget) {
        $py = Find-Python
        if ($py) {
            $pythonForShim = $py.Exe
            Write-Warn "No local venv entry found; shims will use system Python -m hermes_cli.main"
        } else {
            Write-Fail "SkipInstall but no python/eva/hermes found to point shims at"
            exit 1
        }
    }
}

# Prefer hermes.exe as dual target if only one exists
if (-not $evaTarget -and $hermesTarget) { $evaTarget = $hermesTarget }
if (-not $hermesTarget -and $evaTarget) { $hermesTarget = $evaTarget }

# --- Write shims + PATH ------------------------------------------------------
if (-not (Test-Path -LiteralPath $ShimsDir)) {
    New-Item -ItemType Directory -Path $ShimsDir -Force | Out-Null
    Write-Ok ("Created shims dir {0}" -f $ShimsDir)
}

$evaCmd = Join-Path $ShimsDir "eva.cmd"
$hermesCmd = Join-Path $ShimsDir "hermes.cmd"

New-CmdShim -Path $evaCmd -TargetExe $evaTarget -ModuleFallback "hermes_cli.main" `
    -PythonExe $pythonForShim -HomePath $EvaHome
Write-Ok ("Wrote {0}" -f $evaCmd)

New-CmdShim -Path $hermesCmd -TargetExe $hermesTarget -ModuleFallback "hermes_cli.main" `
    -PythonExe $pythonForShim -HomePath $EvaHome
Write-Ok ("Wrote {0}" -f $hermesCmd)

[void](Add-UserPathDir -Dir $ShimsDir)

# --- Verify ------------------------------------------------------------------
$verifyOk = $true
if (-not $SkipVerify) {
    Write-Info "Verify: eva.cmd --help (via cmd.exe)"
    try {
        $out = & cmd.exe /c "`"$evaCmd`" --help" 2>&1
        $code = $LASTEXITCODE
        $text = ($out | Out-String)
        if ($code -eq 0 -or $text -match "(?i)(usage:|commands:|options:|eva|hermes)") {
            Write-Ok "eva.cmd --help ok"
        } else {
            Write-Fail ("eva.cmd --help failed (exit {0})" -f $code)
            if ($text) {
                $snippet = $text.Substring(0, [Math]::Min(400, $text.Length))
                Write-Host $snippet -ForegroundColor DarkGray
            }
            $verifyOk = $false
        }
    } catch {
        Write-Fail ("Verify threw: {0}" -f $_.Exception.Message)
        $verifyOk = $false
    }
} else {
    Write-Warn "Skipping verify (-SkipVerify)"
}

# --- Summary -----------------------------------------------------------------
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
if ($verifyOk) {
    Write-Ok "User PATH install complete"
} else {
    Write-Fail "Finished with verify failures"
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Close this terminal and open a NEW one (PATH refresh)"
Write-Host "  2. Run:"
Write-Host "       eva --help" -ForegroundColor White
Write-Host "       eva setup" -ForegroundColor White
Write-Host "  3. Data home: $EvaHome"
Write-Host "  4. Undo PATH wiring:"
Write-Host "       powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install-user-path.ps1 -Remove"
Write-Host ""
Write-Host "Docs: docs\install-windows.md (section PATH permanente)"
Write-Host "Full managed install (Git/Node/uv portable): scripts\install.ps1"
Write-Host ""

if ($verifyOk) { exit 0 } else { exit 1 }
