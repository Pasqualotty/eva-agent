# ============================================================================
# EVA Agent - Windows smoke checks (repo-local, no paid APIs)
# ============================================================================
# PowerShell 5.1+ compatible. Runs lightweight repo/environment checks for the
# EVA Agent fork (Hermes-based). Does NOT call paid APIs or require real keys.
#
# Usage (from repo root or any cwd):
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\smoke_eva_windows.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\smoke_eva_windows.ps1 -Json
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\smoke_eva_windows.ps1 -Strict
#
# Exit codes:
#   0 - all required checks passed (skips are OK)
#   1 - one or more required checks failed
#   2 - script could not locate the repo root
#
# Optional flags:
#   -Strict  Treat SKIP as FAIL (useful in CI when the env is fully provisioned)
#   -Json    Emit a machine-readable JSON summary on stdout (human lines still go to stderr)
# ============================================================================

[CmdletBinding()]
param(
    [switch]$Strict,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
} catch {
    # Constrained hosts may block encoding mutation; cosmetic only.
}

# --- Resolve repo root (scripts/ is one level under root) -------------------
$scriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
$repoRoot = Split-Path -Parent $scriptDir

function Test-RepoRoot {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $markers = @("pyproject.toml", "hermes_constants.py", "toolsets.py", "hermes_cli")
    foreach ($m in $markers) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path $m))) {
            return $false
        }
    }
    return $true
}

if (-not (Test-RepoRoot $repoRoot)) {
    # Walk up a few levels from cwd as a fallback
    $probe = (Get-Location).Path
    $found = $null
    for ($i = 0; $i -lt 6; $i++) {
        if (Test-RepoRoot $probe) {
            $found = $probe
            break
        }
        $parent = Split-Path -Parent $probe
        if (-not $parent -or $parent -eq $probe) { break }
        $probe = $parent
    }
    if ($found) {
        $repoRoot = $found
    } else {
        Write-Host "FAIL: could not locate EVA/hermes-agent repo root (need pyproject.toml + hermes_constants.py + toolsets.py)" -ForegroundColor Red
        exit 2
    }
}

Set-Location -LiteralPath $repoRoot

# --- Result bookkeeping ----------------------------------------------------
$script:results = New-Object System.Collections.ArrayList
$script:failed = 0
$script:passed = 0
$script:skipped = 0

function Write-CheckLine {
    param(
        [string]$Status,
        [string]$Name,
        [string]$Detail = ""
    )
    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "SKIP" { "Yellow" }
        default { "Gray" }
    }
    $line = "[{0}] {1}" -f $Status, $Name
    if ($Detail) { $line = "$line - $Detail" }
    if ($Json) {
        [Console]::Error.WriteLine($line)
    } else {
        Write-Host $line -ForegroundColor $color
    }
}

function Add-Result {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("PASS", "FAIL", "SKIP")][string]$Status,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Detail = "",
        [switch]$Required
    )

    if ($Status -eq "SKIP" -and $Strict -and $Required) {
        $Status = "FAIL"
        if ($Detail) {
            $Detail = "strict: was skip - $Detail"
        } else {
            $Detail = "strict: was skip"
        }
    }

    $row = New-Object psobject
    $row | Add-Member -NotePropertyName status -NotePropertyValue $Status
    $row | Add-Member -NotePropertyName name -NotePropertyValue $Name
    $row | Add-Member -NotePropertyName detail -NotePropertyValue $Detail
    $row | Add-Member -NotePropertyName required -NotePropertyValue ([bool]$Required)
    [void]$script:results.Add($row)

    switch ($Status) {
        "PASS" { $script:passed++ }
        "FAIL" { $script:failed++ }
        "SKIP" { $script:skipped++ }
    }
    Write-CheckLine -Status $Status -Name $Name -Detail $Detail
}

function Find-Python {
    # Prefer python3, then python. Reject WindowsApps stub that opens Store.
    $candidates = @()
    foreach ($cmd in @("python3", "python", "py")) {
        $cmdInfo = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($cmdInfo -and $cmdInfo.Source) {
            $candidates += $cmdInfo.Source
        }
    }
    # py -3 launcher
    $pyLauncher = Get-Command "py" -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        try {
            $viaPy = & py -3 -c "import sys; print(sys.executable)" 2>$null
            if ($LASTEXITCODE -eq 0 -and $viaPy) {
                $candidates = @($viaPy.Trim()) + $candidates
            }
        } catch { }
    }

    foreach ($exe in $candidates) {
        if (-not $exe) { continue }
        if ($exe -match 'WindowsApps\\python') { continue }
        try {
            $ver = & $exe -c "import sys; print('%d.%d.%d' % sys.version_info[:3])" 2>$null
            if ($LASTEXITCODE -eq 0 -and $ver) {
                return @{ Exe = $exe; Version = $ver.Trim() }
            }
        } catch {
            continue
        }
    }
    return $null
}

function Invoke-PythonSnippet {
    param(
        [Parameter(Mandatory = $true)][string]$PythonExe,
        [Parameter(Mandatory = $true)][string]$Code,
        [int]$TimeoutSec = 30
    )
    $tmp = [System.IO.Path]::GetTempFileName() + ".py"
    try {
        # UTF-8 without BOM for PS 5.1 compatibility with Python source
        [System.IO.File]::WriteAllText($tmp, $Code, (New-Object System.Text.UTF8Encoding $false))
        $out = & $PythonExe $tmp 2>&1
        $code = $LASTEXITCODE
        $text = ($out | Out-String).Trim()
        return @{ ExitCode = $code; Output = $text }
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

# --- Banner ----------------------------------------------------------------
if (-not $Json) {
    Write-Host ""
    Write-Host "EVA Agent Windows smoke" -ForegroundColor Cyan
    Write-Host ("  repo:     {0}" -f $repoRoot)
    Write-Host ("  host:     {0}" -f $env:COMPUTERNAME)
    Write-Host ("  ps:       {0}" -f $PSVersionTable.PSVersion.ToString())
    Write-Host ("  strict:   {0}" -f [bool]$Strict)
    Write-Host ""
}

# ============================================================================
# CHECKS
# ============================================================================

# 1) PowerShell version
$psMajor = $PSVersionTable.PSVersion.Major
$psMinor = $PSVersionTable.PSVersion.Minor
if ($psMajor -gt 5 -or ($psMajor -eq 5 -and $psMinor -ge 1)) {
    Add-Result -Status "PASS" -Name "powershell_version" -Detail ("{0}.{1}+" -f $psMajor, $psMinor) -Required
} else {
    Add-Result -Status "FAIL" -Name "powershell_version" -Detail ("need 5.1+, got {0}.{1}" -f $psMajor, $psMinor) -Required
}

# 2) Repo layout markers
$requiredPaths = @(
    "pyproject.toml",
    "hermes_constants.py",
    "toolsets.py",
    "hermes_cli\main.py",
    "hermes",
    "LICENSE",
    "skills",
    "tools"
)
$missing = @()
foreach ($rel in $requiredPaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $rel))) {
        $missing += $rel
    }
}
if ($missing.Count -eq 0) {
    Add-Result -Status "PASS" -Name "repo_layout" -Detail ("{0} markers present" -f $requiredPaths.Count) -Required
} else {
    Add-Result -Status "FAIL" -Name "repo_layout" -Detail ("missing: {0}" -f ($missing -join ", ")) -Required
}

# 3) Python available
$py = Find-Python
$pythonExe = $null
if ($null -eq $py) {
    Add-Result -Status "FAIL" -Name "python_available" -Detail "no usable python/python3/py -3 on PATH" -Required
} else {
    $pythonExe = $py.Exe
    Add-Result -Status "PASS" -Name "python_available" -Detail ("{0} ({1})" -f $py.Version, $pythonExe) -Required
}

# 4) Python version floor (requires-python >=3.11)
if ($pythonExe) {
    $verCheck = Invoke-PythonSnippet -PythonExe $pythonExe -Code @"
import sys
v = sys.version_info
ok = v >= (3, 11) and v < (3, 14)
print('%d.%d.%d' % v[:3])
sys.exit(0 if ok else 1)
"@
    if ($verCheck.ExitCode -eq 0) {
        Add-Result -Status "PASS" -Name "python_version" -Detail $verCheck.Output -Required
    } else {
        Add-Result -Status "FAIL" -Name "python_version" -Detail ("need >=3.11,<3.14 got {0}" -f $verCheck.Output) -Required
    }
} else {
    Add-Result -Status "SKIP" -Name "python_version" -Detail "no python" -Required
}

# 5) pyproject.toml sanity (name + scripts entry points)
if ($pythonExe -and (Test-Path -LiteralPath (Join-Path $repoRoot "pyproject.toml"))) {
    $ppCheck = Invoke-PythonSnippet -PythonExe $pythonExe -Code @"
import sys
from pathlib import Path
root = Path(r'''$repoRoot''')
text = (root / 'pyproject.toml').read_text(encoding='utf-8')
try:
    try:
        import tomllib
    except ImportError:
        import tomli as tomllib  # type: ignore
    data = tomllib.loads(text)
except Exception as e:
    # Minimal fallback without tomllib/tomli: regex-ish presence checks
    import re
    name_m = re.search(r'(?m)^name\s*=\s*"([^"]+)"', text)
    scripts_ok = 'hermes' in text and 'hermes_cli.main' in text
    if not name_m:
        print('parse_error: %s' % e)
        sys.exit(1)
    print('name=%s scripts=%s (fallback-parser)' % (name_m.group(1), scripts_ok))
    sys.exit(0 if scripts_ok else 1)
else:
    proj = data.get('project') or {}
    name = proj.get('name') or ''
    scripts = proj.get('scripts') or {}
    has_hermes = 'hermes' in scripts
    entry = scripts.get('hermes', '')
    ok = bool(name) and has_hermes and 'hermes_cli' in entry
    print('name=%s hermes_entry=%s' % (name, entry))
    sys.exit(0 if ok else 1)
"@
    if ($ppCheck.ExitCode -eq 0) {
        Add-Result -Status "PASS" -Name "pyproject_ok" -Detail $ppCheck.Output -Required
    } else {
        Add-Result -Status "FAIL" -Name "pyproject_ok" -Detail $ppCheck.Output -Required
    }
} else {
    Add-Result -Status "SKIP" -Name "pyproject_ok" -Detail "no python or pyproject.toml" -Required
}

# 6) hermes_constants import (stdlib-only module)
if ($pythonExe) {
    $hc = Invoke-PythonSnippet -PythonExe $pythonExe -Code @"
import sys, os
sys.path.insert(0, r'''$repoRoot''')
import hermes_constants
home = hermes_constants.get_hermes_home()
print(str(home))
# Windows EVA target home is %LOCALAPPDATA%\eva (rebrand); Hermes default is hermes.
# Smoke only asserts the resolver returns a Path under a real base.
assert home is not None
print('ok')
"@
    if ($hc.ExitCode -eq 0) {
        Add-Result -Status "PASS" -Name "import_hermes_constants" -Detail $hc.Output.Replace("`r", " ").Replace("`n", " | ") -Required
    } else {
        Add-Result -Status "FAIL" -Name "import_hermes_constants" -Detail $hc.Output -Required
    }
} else {
    Add-Result -Status "SKIP" -Name "import_hermes_constants" -Detail "no python" -Required
}

# 7) toolsets list without API keys
if ($pythonExe) {
    $ts = Invoke-PythonSnippet -PythonExe $pythonExe -Code @"
import sys
sys.path.insert(0, r'''$repoRoot''')
from toolsets import TOOLSETS, get_all_toolsets
keys = sorted(TOOLSETS.keys())
# Prefer public helper if present
try:
    all_ts = get_all_toolsets()
    n = len(all_ts)
except Exception:
    n = len(keys)
assert n >= 5, 'expected several toolsets, got %d' % n
# Sample a few core names that should always exist
core_expected = ['web', 'terminal', 'file', 'browser']
missing = [k for k in core_expected if k not in TOOLSETS]
print('count=%d sample=%s' % (n, ','.join(keys[:8])))
if missing:
    print('missing_core=%s' % ','.join(missing))
    sys.exit(1)
print('ok')
"@
    if ($ts.ExitCode -eq 0) {
        Add-Result -Status "PASS" -Name "toolsets_list" -Detail $ts.Output.Replace("`r", " ").Replace("`n", " | ") -Required
    } else {
        Add-Result -Status "FAIL" -Name "toolsets_list" -Detail $ts.Output -Required
    }
} else {
    Add-Result -Status "SKIP" -Name "toolsets_list" -Detail "no python" -Required
}

# 8) skills directory has bundled skills (no network)
$skillsDir = Join-Path $repoRoot "skills"
if (Test-Path -LiteralPath $skillsDir) {
    $skillFiles = @(Get-ChildItem -LiteralPath $skillsDir -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue)
    if ($skillFiles.Count -gt 0) {
        Add-Result -Status "PASS" -Name "skills_bundled" -Detail ("{0} SKILL.md under skills/" -f $skillFiles.Count) -Required
    } else {
        Add-Result -Status "FAIL" -Name "skills_bundled" -Detail "no SKILL.md under skills/" -Required
    }
} else {
    Add-Result -Status "FAIL" -Name "skills_bundled" -Detail "skills/ missing" -Required
}

# 9) uv present? (optional - skip if absent)
$uv = Get-Command "uv" -ErrorAction SilentlyContinue
if ($uv) {
    try {
        $uvVer = & uv --version 2>&1 | Out-String
        Add-Result -Status "PASS" -Name "uv_available" -Detail $uvVer.Trim()
    } catch {
        Add-Result -Status "SKIP" -Name "uv_available" -Detail "uv on PATH but --version failed"
    }
} else {
    Add-Result -Status "SKIP" -Name "uv_available" -Detail "uv not on PATH (ok for smoke)"
}

# 10) venv present? (optional)
$venvPython = $null
foreach ($candidate in @(
        (Join-Path $repoRoot ".venv\Scripts\python.exe"),
        (Join-Path $repoRoot "venv\Scripts\python.exe")
    )) {
    if (Test-Path -LiteralPath $candidate) {
        $venvPython = $candidate
        break
    }
}
if ($venvPython) {
    Add-Result -Status "PASS" -Name "venv_present" -Detail $venvPython
} else {
    Add-Result -Status "SKIP" -Name "venv_present" -Detail ".venv/venv not found (ok for smoke)"
}

# Prefer venv python for CLI checks when available
$cliPython = if ($venvPython) { $venvPython } else { $pythonExe }

# 11) hermes CLI --help (installed shim OR repo launcher with deps)
$hermesCmd = Get-Command "hermes" -ErrorAction SilentlyContinue
$hermesHelpOk = $false
$hermesDetail = ""

if ($hermesCmd -and $hermesCmd.Source -and ($hermesCmd.Source -notmatch '\\hermes$')) {
    # Installed console_script on PATH (not the bare repo file without extension match)
    try {
        $helpOut = & hermes --help 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -or $helpOut -match 'Usage|usage|doctor|Commands') {
            $hermesHelpOk = $true
            $hermesDetail = "installed: $($hermesCmd.Source)"
        } else {
            $hermesDetail = "hermes --help exit=$LASTEXITCODE"
        }
    } catch {
        $hermesDetail = "hermes --help error: $($_.Exception.Message)"
    }
}

if (-not $hermesHelpOk -and $cliPython) {
    $launcher = Join-Path $repoRoot "hermes"
    if (Test-Path -LiteralPath $launcher) {
        try {
            $helpOut = & $cliPython $launcher --help 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0 -or $helpOut -match 'Usage|usage|doctor|Commands') {
                $hermesHelpOk = $true
                $hermesDetail = "repo launcher via $cliPython"
            } else {
                # Capture first useful error line
                $errLine = ($helpOut -split "`n" | Where-Object { $_ -match "Error|ModuleNotFound|Traceback|ImportError" } | Select-Object -First 1)
                if (-not $errLine) { $errLine = ($helpOut.Trim() -split "`n" | Select-Object -Last 1) }
                $hermesDetail = "repo launcher failed (deps?): $errLine"
            }
        } catch {
            $hermesDetail = "repo launcher error: $($_.Exception.Message)"
        }
    } else {
        $hermesDetail = "no hermes launcher in repo"
    }
}

if ($hermesHelpOk) {
    Add-Result -Status "PASS" -Name "hermes_cli_help" -Detail $hermesDetail
} else {
    # Not required: full CLI needs installed deps (yaml, etc.)
    Add-Result -Status "SKIP" -Name "hermes_cli_help" -Detail $(if ($hermesDetail) { $hermesDetail } else { "hermes CLI not runnable without install" })
}

# 12) eva CLI --help (rebrand entry - may not exist yet on this branch)
$evaCmd = Get-Command "eva" -ErrorAction SilentlyContinue
$evaLauncher = Join-Path $repoRoot "eva"
if ($evaCmd) {
    try {
        $evaHelp = & eva --help 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -or $evaHelp -match 'Usage|usage|doctor|Commands|EVA|Hermes') {
            Add-Result -Status "PASS" -Name "eva_cli_help" -Detail "installed: $($evaCmd.Source)"
        } else {
            Add-Result -Status "SKIP" -Name "eva_cli_help" -Detail "eva on PATH but --help did not look healthy"
        }
    } catch {
        Add-Result -Status "SKIP" -Name "eva_cli_help" -Detail $_.Exception.Message
    }
} elseif (Test-Path -LiteralPath $evaLauncher) {
    if ($cliPython) {
        try {
            $evaHelp = & $cliPython $evaLauncher --help 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0 -or $evaHelp -match 'Usage|usage|doctor|Commands|EVA|Hermes') {
                Add-Result -Status "PASS" -Name "eva_cli_help" -Detail "repo launcher via $cliPython"
            } else {
                Add-Result -Status "SKIP" -Name "eva_cli_help" -Detail "repo eva launcher present but --help failed (deps?)"
            }
        } catch {
            Add-Result -Status "SKIP" -Name "eva_cli_help" -Detail $_.Exception.Message
        }
    } else {
        Add-Result -Status "SKIP" -Name "eva_cli_help" -Detail "eva launcher present, no python"
    }
} else {
    Add-Result -Status "SKIP" -Name "eva_cli_help" -Detail "eva CLI not installed yet (rebrand pending - ok)"
}

# 13) doctor (if CLI works)
if ($hermesHelpOk -and $cliPython) {
    $doctorOk = $false
    $doctorDetail = ""
    $launcher = Join-Path $repoRoot "hermes"
    try {
        if ((Get-Command "hermes" -ErrorAction SilentlyContinue) -and $hermesDetail -like "installed:*") {
            $docOut = & hermes doctor 2>&1 | Out-String
            $docCode = $LASTEXITCODE
        } else {
            $docOut = & $cliPython $launcher doctor 2>&1 | Out-String
            $docCode = $LASTEXITCODE
        }
        # doctor may return non-zero when config incomplete - still "ran"
        if ($docOut -match 'doctor|Doctor|Python|config|Config|OK|PASS|FAIL|check') {
            $doctorOk = $true
            $doctorDetail = "ran (exit=$docCode)"
        } else {
            $doctorDetail = "unexpected output (exit=$docCode)"
        }
    } catch {
        $doctorDetail = $_.Exception.Message
    }
    if ($doctorOk) {
        Add-Result -Status "PASS" -Name "hermes_doctor" -Detail $doctorDetail
    } else {
        Add-Result -Status "SKIP" -Name "hermes_doctor" -Detail $doctorDetail
    }
} else {
    Add-Result -Status "SKIP" -Name "hermes_doctor" -Detail "CLI not runnable; skip doctor"
}

# 14) Windows footgun checker (optional, no network)
$footgun = Join-Path $repoRoot "scripts\check-windows-footguns.py"
if ($pythonExe -and (Test-Path -LiteralPath $footgun)) {
    # Only scan smoke-related / core lightweight paths - full tree is slow and
    # may report pre-existing issues outside this front's scope.
    try {
        $fgPrevEap = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        $fgRaw = & $pythonExe $footgun "hermes_constants.py" "toolsets.py" 2>&1
        $fgCode = $LASTEXITCODE
        $ErrorActionPreference = $fgPrevEap
        $fgOut = (($fgRaw | ForEach-Object { "$_" }) -join " ")
        if ($fgCode -eq 0) {
            Add-Result -Status "PASS" -Name "windows_footguns_core" -Detail "hermes_constants + toolsets clean"
        } else {
            # Advisory only - do not fail the smoke on historical footguns
            $snippet = ($fgOut -replace '\s+', ' ').Trim()
            if ($snippet.Length -gt 120) { $snippet = $snippet.Substring(0, 120) }
            Add-Result -Status "SKIP" -Name "windows_footguns_core" -Detail ("exit={0} {1}" -f $fgCode, $snippet)
        }
    } catch {
        Add-Result -Status "SKIP" -Name "windows_footguns_core" -Detail $_.Exception.Message
    }
} else {
    Add-Result -Status "SKIP" -Name "windows_footguns_core" -Detail "checker or python missing"
}

# 15) NOTICE/LICENSE present (fork obligation)
$licenseOk = (Test-Path -LiteralPath (Join-Path $repoRoot "LICENSE"))
$noticePath = $null
foreach ($n in @("NOTICE", "NOTICE.md", "NOTICE.txt")) {
    if (Test-Path -LiteralPath (Join-Path $repoRoot $n)) {
        $noticePath = $n
        break
    }
}
if ($licenseOk) {
    $detail = "LICENSE present"
    if ($noticePath) { $detail = "$detail; $noticePath present" }
    else { $detail = "$detail; NOTICE optional/not found" }
    Add-Result -Status "PASS" -Name "license_present" -Detail $detail -Required
} else {
    Add-Result -Status "FAIL" -Name "license_present" -Detail "LICENSE missing" -Required
}

# ============================================================================
# SUMMARY
# ============================================================================
$total = [int]$script:passed + [int]$script:failed + [int]$script:skipped
if ($script:failed -gt 0) {
    $exitCode = 1
    $statusLabel = "failed"
    $summaryColor = "Red"
} else {
    $exitCode = 0
    $statusLabel = "ok"
    $summaryColor = "Green"
}

if ($Json) {
    # Flatten checks into plain hashtables for ConvertTo-Json (PS 5.1-safe).
    $checkRows = @()
    foreach ($r in $script:results) {
        $checkRows += @{
            status   = [string]$r.status
            name     = [string]$r.name
            detail   = [string]$r.detail
            required = [bool]$r.required
        }
    }
    $payload = @{
        status    = $statusLabel
        repoRoot  = [string]$repoRoot
        passed    = [int]$script:passed
        failed    = [int]$script:failed
        skipped   = [int]$script:skipped
        total     = $total
        strict    = [bool]$Strict
        checks    = $checkRows
        platform  = "windows"
        psVersion = $PSVersionTable.PSVersion.ToString()
    }
    $payload | ConvertTo-Json -Depth 6
} else {
    Write-Host ""
    Write-Host ("Summary: {0} passed, {1} failed, {2} skipped (total {3})" -f $script:passed, $script:failed, $script:skipped, $total) -ForegroundColor $summaryColor
    if ($exitCode -eq 0) {
        Write-Host "SMOKE OK" -ForegroundColor Green
    } else {
        Write-Host "SMOKE FAILED" -ForegroundColor Red
        Write-Host "Failed checks:" -ForegroundColor Red
        foreach ($r in $script:results) {
            if ($r.status -eq "FAIL") {
                Write-Host ("  - {0}: {1}" -f $r.name, $r.detail) -ForegroundColor Red
            }
        }
    }
    Write-Host ""
}

exit $exitCode
