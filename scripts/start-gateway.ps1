# ============================================================================
# EVA Agent - start messaging gateway in background (Windows)
# ============================================================================
# Starts the gateway without requiring any bot token in the git repo.
# Secrets are read only from %LOCALAPPDATA%\eva\.env (or EVA_HOME/HERMES_HOME).
#
# Usage (from repo root or any cwd):
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\start-gateway.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\start-gateway.ps1 -Install
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\start-gateway.ps1 -StatusOnly
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\start-gateway.ps1 -Force
#
# Exit codes:
#   0 - gateway already running, started, or -StatusOnly completed
#   1 - missing TELEGRAM_BOT_TOKEN, CLI not found, or start failed
#   2 - could not resolve EVA home / repo
#
# Notes:
#   - NEVER commits secrets. Token lives only under the user data home.
#   - Prefer `eva gateway start` when the Windows service is installed.
#   - Otherwise detaches `eva gateway run` (Start-Process / pythonw-style).
#   - Optional -Install registers login auto-start via `eva gateway install`
#     with non-interactive env (HERMES_GATEWAY_INSTALL_*).
#   - Keep this file ASCII-only for Windows PowerShell 5.1 parser safety.
# ============================================================================

[CmdletBinding()]
param(
    # Also install Scheduled Task / Startup login auto-start (non-interactive).
    [switch]$Install,
    # Skip TELEGRAM_BOT_TOKEN presence check (other platforms only).
    [switch]$SkipTokenCheck,
    # Only run doctor/status; do not start.
    [switch]$StatusOnly,
    # If already running, stop then start.
    [switch]$Force,
    # Wait N seconds after start and re-check status (0 = no wait).
    [int]$ReadySeconds = 4
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

function Get-EnvFileValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Key
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $lines = Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        $t = $line.Trim()
        if (-not $t -or $t.StartsWith("#")) { continue }
        $eq = $t.IndexOf("=")
        if ($eq -lt 1) { continue }
        $k = $t.Substring(0, $eq).Trim()
        if ($k -ne $Key) { continue }
        $v = $t.Substring($eq + 1).Trim()
        # strip optional surrounding quotes
        if (($v.StartsWith('"') -and $v.EndsWith('"')) -or ($v.StartsWith("'") -and $v.EndsWith("'"))) {
            if ($v.Length -ge 2) { $v = $v.Substring(1, $v.Length - 2) }
        }
        return $v
    }
    return $null
}

function Test-PlaceholderToken {
    param([string]$Value)
    if (-not $Value) { return $true }
    $v = $Value.Trim()
    if (-not $v) { return $true }
    $placeholders = @(
        "REPLACE_WITH_BOTFATHER_TOKEN",
        "REPLACE_ME",
        "YOUR_TOKEN",
        "CHANGEME",
        "TODO",
        "xxx",
        "..."
    )
    foreach ($p in $placeholders) {
        if ($v -ieq $p) { return $true }
    }
    if ($v -match '^(REPLACE|CHANGE|INSERT|PASTE|YOUR_|<.*>)$') { return $true }
    # Real BotFather tokens look like digits:alnum (very rough; do not log value)
    return $false
}

function Show-MissingTokenHelp {
    param([string]$EnvPath)
    Write-Host ""
    Write-Fail "TELEGRAM_BOT_TOKEN missing or still a placeholder."
    Write-Host ""
    Write-Host "O gateway NAO le token do git. Cole o token so no arquivo local:" -ForegroundColor Yellow
    Write-Host ("  {0}" -f $EnvPath) -ForegroundColor White
    Write-Host ""
    Write-Host "O que fazer (so humano - UI Telegram):" -ForegroundColor Cyan
    Write-Host "  1. Abra https://t.me/BotFather"
    Write-Host "  2. /newbot (ou use um bot ja criado) e COPIE o token"
    Write-Host "  3. Edite o .env e preencha:"
    Write-Host ""
    Write-Host "     TELEGRAM_BOT_TOKEN=<cole o token do BotFather aqui>"
    Write-Host "     TELEGRAM_ALLOWED_USERS=<seu user id numerico>"
    Write-Host ""
    Write-Host "  User ID numerico: @userinfobot ou @get_id_bot no Telegram"
    Write-Host "  Template no repo (sem secrets): docs\gateway.env.example"
    Write-Host "  Wizard alternativo: eva gateway setup"
    Write-Host ""
    Write-Host "Depois rode de novo:" -ForegroundColor Cyan
    Write-Host "  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\start-gateway.ps1"
    Write-Host ""
}

function Find-EvaCommand {
    param([string]$RepoRoot)

    # 1) PATH
    $cmd = Get-Command "eva" -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return @{ Kind = "exe"; Path = $cmd.Source; ArgsPrefix = @() }
    }
    $cmdH = Get-Command "hermes" -ErrorAction SilentlyContinue
    if ($cmdH -and $cmdH.Source) {
        return @{ Kind = "exe"; Path = $cmdH.Source; ArgsPrefix = @() }
    }

    # 2) Managed install: %LOCALAPPDATA%\eva\eva-agent\.venv\Scripts\eva.exe
    $managed = Join-Path (Get-EvaHome) "eva-agent\.venv\Scripts\eva.exe"
    if (Test-Path -LiteralPath $managed) {
        return @{ Kind = "exe"; Path = $managed; ArgsPrefix = @() }
    }
    $managedH = Join-Path (Get-EvaHome) "eva-agent\.venv\Scripts\hermes.exe"
    if (Test-Path -LiteralPath $managedH) {
        return @{ Kind = "exe"; Path = $managedH; ArgsPrefix = @() }
    }

    # 3) Repo-local venv
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

    # 4) System python + repo on PYTHONPATH (dev)
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
        [Parameter(Mandatory = $true)][string[]]$GatewayArgs,
        [switch]$PassThru,
        [string]$WorkDir
    )
    $argList = @()
    if ($Eva.ArgsPrefix) { $argList += $Eva.ArgsPrefix }
    $argList += $GatewayArgs
    $wd = $WorkDir
    if (-not $wd -and $Eva.WorkDir) { $wd = $Eva.WorkDir }

    # Detached background start (no wait)
    if ($PassThru) {
        $startArgs = @{
            FilePath         = $Eva.Path
            ArgumentList     = $argList
            WindowStyle      = "Hidden"
            WorkingDirectory = $(if ($wd) { $wd } else { (Get-Location).Path })
            PassThru         = $true
        }
        return (Start-Process @startArgs)
    }

    # Foreground: stream CLI output to host; function returns ONLY exit code.
    # (Bare `&` would leak stdout into the caller's assignment via the success stream.)
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
$envPath = Join-Path $evaHome ".env"
$repoRoot = Resolve-RepoRoot

# Ensure process env points at user data home (not repo)
$env:EVA_HOME = $evaHome
$env:HERMES_HOME = $evaHome
# Scripted path: never hang on y/N prompts (see hermes_cli.setup.is_noninteractive)
$env:HERMES_NONINTERACTIVE = "1"

Write-Host ""
Write-Host "EVA Agent - start gateway (Windows)" -ForegroundColor Cyan
Write-Host ("  home:  {0}" -f $evaHome)
Write-Host ("  env:   {0}" -f $envPath)
if ($repoRoot) { Write-Host ("  repo:  {0}" -f $repoRoot) }
Write-Host ""

# Ensure home + logs dirs exist (do not create .env automatically with secrets)
New-Item -ItemType Directory -Force -Path $evaHome | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $evaHome "logs") | Out-Null

# --- Token gate (no secrets in git) ------------------------------------------
# StatusOnly is doctor-only: allow without token so operators can inspect state.
if ((-not $SkipTokenCheck) -and (-not $StatusOnly)) {
    $token = Get-EnvFileValue -Path $envPath -Key "TELEGRAM_BOT_TOKEN"
    if (Test-PlaceholderToken $token) {
        if (-not (Test-Path -LiteralPath $envPath)) {
            Write-Warn (".env ainda nao existe em {0}" -f $evaHome)
            Write-Info "Criando .env vazio a partir do template do repo (placeholders only)..."
            $template = $null
            if ($repoRoot) {
                $t1 = Join-Path $repoRoot "docs\gateway.env.example"
                $t2 = Join-Path $repoRoot ".env.example"
                if (Test-Path -LiteralPath $t1) { $template = $t1 }
                elseif (Test-Path -LiteralPath $t2) { $template = $t2 }
            }
            if ($template) {
                Copy-Item -LiteralPath $template -Destination $envPath
                Write-Ok ("Copiado template -> {0}" -f $envPath)
            } else {
                @(
                    "# EVA Agent - local secrets only. NEVER commit this file.",
                    "TELEGRAM_BOT_TOKEN=REPLACE_WITH_BOTFATHER_TOKEN",
                    "TELEGRAM_ALLOWED_USERS=REPLACE_WITH_YOUR_NUMERIC_USER_ID"
                ) | Set-Content -LiteralPath $envPath -Encoding UTF8
                Write-Ok ("Criado stub .env -> {0}" -f $envPath)
            }
        }
        Show-MissingTokenHelp -EnvPath $envPath
        exit 1
    }
    Write-Ok "TELEGRAM_BOT_TOKEN presente no .env local (valor nao exibido)"
}

# --- Resolve CLI -------------------------------------------------------------
$eva = Find-EvaCommand -RepoRoot $repoRoot
if (-not $eva) {
    Write-Fail "CLI 'eva' (ou hermes) nao encontrada."
    Write-Host "  Instale/bootstrap:"
    Write-Host "    powershell -File scripts\bootstrap_dev.ps1"
    Write-Host "    # ou install.ps1 / PATH com %LOCALAPPDATA%\eva\eva-agent\.venv\Scripts"
    exit 1
}
Write-Ok ("CLI: {0}" -f $eva.Path)

# --- Doctor: eva gateway status ----------------------------------------------
Write-Info "Doctor: eva gateway status"
try {
    $null = Invoke-Eva -Eva $eva -GatewayArgs @("gateway", "status")
} catch {
    Write-Warn ("gateway status falhou (continua): {0}" -f $_.Exception.Message)
}

if ($StatusOnly) {
    Write-Ok "StatusOnly - sem start."
    exit 0
}

# --- Force restart -----------------------------------------------------------
if ($Force) {
    Write-Info "Force: parando gateway se estiver rodando..."
    try {
        $null = Invoke-Eva -Eva $eva -GatewayArgs @("gateway", "stop")
    } catch {
        Write-Warn ("stop: {0}" -f $_.Exception.Message)
    }
    Start-Sleep -Seconds 1
}

# --- Optional install (login auto-start) -------------------------------------
if ($Install) {
    Write-Info "Install: registrando auto-start (nao-interativo)..."
    # Non-interactive answers for gateway_windows._prompt_install_choices
    $env:HERMES_GATEWAY_INSTALL_START_NOW = "1"
    $env:HERMES_GATEWAY_INSTALL_START_ON_LOGIN = "1"
    try {
        $code = Invoke-Eva -Eva $eva -GatewayArgs @("gateway", "install")
        if ($code -ne 0) {
            Write-Warn ("gateway install exit={0} (tentando start mesmo assim)" -f $code)
        } else {
            Write-Ok "gateway install concluido"
        }
    } catch {
        Write-Warn ("install: {0}" -f $_.Exception.Message)
    }
    if ($ReadySeconds -gt 0) {
        Start-Sleep -Seconds $ReadySeconds
    }
    Write-Info "Status pos-install:"
    try { $null = Invoke-Eva -Eva $eva -GatewayArgs @("gateway", "status") } catch { }
    Write-Host ""
    Write-Ok "Pronto. Logs: $evaHome\logs\gateway.log"
    exit 0
}

# --- Start in background -----------------------------------------------------
# Prefer direct Hidden detach of `gateway run` so we never block on install/UAC
# unless the user passed -Install. Then try `eva gateway start` (service path).
Write-Info "Iniciando gateway em background..."

$startedVia = $null

# Path A: Start-Process Hidden -> gateway run (always non-interactive)
try {
    Write-Info "Detach: Start-Process Hidden -> eva gateway run"
    $p = Invoke-Eva -Eva $eva -GatewayArgs @("gateway", "run") -PassThru
    if ($p -and $p.Id) {
        Write-Ok ("Processo detached PID {0}" -f $p.Id)
        $startedVia = "Start-Process gateway run"
    }
} catch {
    Write-Warn ("detach gateway run: {0}" -f $_.Exception.Message)
}

# Path B: official start (Scheduled Task / installed service / spawn_detached)
if (-not $startedVia) {
    try {
        Write-Info "Tentando: eva gateway start"
        $code = Invoke-Eva -Eva $eva -GatewayArgs @("gateway", "start")
        if ($code -eq 0) {
            $startedVia = "eva gateway start"
        } else {
            Write-Warn ("gateway start exit={0}" -f $code)
        }
    } catch {
        Write-Warn ("gateway start: {0}" -f $_.Exception.Message)
    }
}

if ($ReadySeconds -gt 0) {
    Write-Info ("Aguardando {0}s e rechecando status..." -f $ReadySeconds)
    Start-Sleep -Seconds $ReadySeconds
}

Write-Info "Doctor pos-start: eva gateway status"
try {
    $null = Invoke-Eva -Eva $eva -GatewayArgs @("gateway", "status")
} catch {
    Write-Warn ("status: {0}" -f $_.Exception.Message)
}

Write-Host ""
if ($startedVia) {
    Write-Ok ("Gateway start acionado via: {0}" -f $startedVia)
} else {
    Write-Fail "Nao foi possivel iniciar o gateway."
    Write-Host "  Verifique: eva doctor   e   logs em $evaHome\logs\"
    exit 1
}

Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Cyan
Write-Host "  - Telegram: abra o bot e envie uma mensagem"
Write-Host ("  - Logs: Get-Content '{0}\logs\gateway.log' -Tail 80 -Wait" -f $evaHome)
Write-Host "  - Parar:  powershell -File scripts\stop-gateway.ps1"
Write-Host "  - Status: eva gateway status"
Write-Host ""
exit 0
