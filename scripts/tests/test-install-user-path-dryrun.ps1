# Smoke tests for install-user-path.ps1 (-DryRun only; no env/PATH writes).
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/test-install-user-path-dryrun.ps1

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$script = Join-Path $repoRoot "scripts\install-user-path.ps1"

if (-not (Test-Path -LiteralPath $script)) {
    throw "Could not locate install-user-path.ps1 at $script"
}

$failures = 0
function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ($Expected -ne $Actual) {
        Write-Host "FAIL: $Label" -ForegroundColor Red
        Write-Host "  expected: $Expected"
        Write-Host "  actual:   $Actual"
        $script:failures++
    } else {
        Write-Host "OK: $Label" -ForegroundColor Green
    }
}
function Assert-True {
    param($Condition, [string]$Label)
    if (-not $Condition) {
        Write-Host "FAIL: $Label" -ForegroundColor Red
        $script:failures++
    } else {
        Write-Host "OK: $Label" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "-- -DryRun (default mode) --"
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $script -DryRun 2>&1 | Out-String
Assert-Equal -Expected 0 -Actual $LASTEXITCODE -Label "-DryRun exits 0"
Assert-True ($output -match "(?i)DRY-RUN|\[DRY\]") -Label "-DryRun prints dry-run markers"
Assert-True ($output -match "EVA_HOME") -Label "-DryRun mentions EVA_HOME"
Assert-True ($output -match "shims") -Label "-DryRun mentions shims"
Assert-True ($output -notmatch "SetEnvironmentVariable") -Label "-DryRun output does not claim env write API"

Write-Host ""
Write-Host "-- -DryRun -Remove --"
$output2 = & powershell -NoProfile -ExecutionPolicy Bypass -File $script -DryRun -Remove 2>&1 | Out-String
Assert-Equal -Expected 0 -Actual $LASTEXITCODE -Label "-DryRun -Remove exits 0"
Assert-True ($output2 -match "(?i)remove|Would remove") -Label "-DryRun -Remove describes removal"

Write-Host ""
Write-Host "-- -DryRun -UserPip --"
$output3 = & powershell -NoProfile -ExecutionPolicy Bypass -File $script -DryRun -UserPip 2>&1 | Out-String
Assert-Equal -Expected 0 -Actual $LASTEXITCODE -Label "-DryRun -UserPip exits 0"
Assert-True ($output3 -match "(?i)user|pip") -Label "-DryRun -UserPip mentions user/pip path"

Write-Host ""
if ($failures -eq 0) {
    Write-Host "All install-user-path dry-run tests passed." -ForegroundColor Green
    exit 0
} else {
    Write-Host ("$failures test(s) failed.") -ForegroundColor Red
    exit 1
}
