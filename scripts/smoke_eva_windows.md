# EVA Agent — Windows smoke (manual + script)

Lightweight checks for the **eva-agent** package (Hermes-engine fork) on Windows.
No paid APIs, no real API keys.

## Prerequisites

- Windows 10/11
- PowerShell **5.1+** (Windows PowerShell or PowerShell 7+)
- Python **3.11–3.13** on PATH (`python`, `python3`, or `py -3`)

Optional (script **skips** if missing):

- `uv`
- Local venv (`.venv` or `venv`)
- Installed `eva` / `hermes` console scripts
- Full editable install (`pip install -e .` or `uv sync`) for CLI `--help` / `doctor`

## One-liner

From the repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke_eva_windows.ps1
```

JSON summary (human lines on stderr):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke_eva_windows.ps1 -Json
```

Strict mode (treat SKIP as FAIL — use only when the env is fully provisioned):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke_eva_windows.ps1 -Strict
```

## What the script checks

| Check | Required? | Notes |
|-------|-----------|--------|
| PowerShell ≥ 5.1 | yes | |
| Repo layout markers | yes | includes `eva`, `hermes`, `gateway/__init__.py`, `gateway/run.py`, `skills`, `toolsets.py`, … |
| Python available + version floor | yes | `>=3.11,<3.14` per `pyproject.toml` |
| `pyproject.toml` package/scripts | yes | package name **`eva-agent`**; primary script **`eva` → `hermes_cli.main:main`** (`hermes` alias OK) |
| `import hermes_constants` | yes | platform default home (clears `EVA_HOME`/`HERMES_HOME` for the probe) |
| `eva_windows_home` | yes | default home **`%LOCALAPPDATA%\eva`** on Windows |
| Toolsets list | yes | `TOOLSETS` includes `web`, `terminal`, `file`, `browser`, **`hermes-gateway`** (no API keys) |
| Bundled skills | yes | counts `skills/**/SKILL.md` (+ optional-skills count in detail) |
| Gateway module | yes | file presence: `gateway/__init__.py`, `run.py`, `session.py`, `config.py` — **no import** (import needs PyYAML) |
| LICENSE present | yes | NOTICE optional |
| `uv` / venv | no | SKIP if absent |
| `eva --help` | no | attempted when repo `eva` launcher / installed shim exists; SKIP if deps missing |
| `hermes --help` | no | compat alias; SKIP if deps not installed |
| `eva doctor` | no | only if CLI help already works |
| Windows footguns on core files | no | advisory |

Exit **0** when all required checks pass (skips are fine). Exit **1** on required failures. Exit **2** if the repo root cannot be found.

## Manual steps (if you prefer not to run the script)

1. Confirm Python:

   ```powershell
   python -c "import sys; print(sys.version); assert sys.version_info >= (3,11)"
   ```

2. Confirm repo imports without install:

   ```powershell
   # Unset overrides so you see the platform default
   Remove-Item Env:EVA_HOME -ErrorAction SilentlyContinue
   Remove-Item Env:HERMES_HOME -ErrorAction SilentlyContinue
   python -c "import hermes_constants; print(hermes_constants.get_hermes_home())"
   # Expect: %LOCALAPPDATA%\eva
   python -c "from toolsets import TOOLSETS; print(len(TOOLSETS), 'hermes-gateway' in TOOLSETS)"
   # Gateway presence (file check only — full import needs yaml):
   Test-Path .\gateway\run.py
   ```

3. After a full install (venv + deps):

   ```powershell
   eva --help          # primary CLI
   hermes --help       # compat alias
   eva doctor
   ```

4. Do **not** run live model/provider calls in smoke — that needs real keys and is out of scope.

## Product notes (EVA fork)

- Canonical fork: https://github.com/Pasqualotty/eva-agent  
- Upstream engine: this repo **is** the agent (do not install Hermes as an external dependency).
- PyPI / package name: **`eva-agent`**
- CLI: **`eva`** (primary); `hermes` remains a one-release compatibility alias
- Windows home: **`%LOCALAPPDATA%\eva`** (env: `EVA_HOME`, compat `HERMES_HOME`)
- POSIX home: `~/.eva`
- Keep Nous Research `LICENSE` / `NOTICE` intact.

## Related

- Installer: `scripts/install.ps1`
- Windows footgun grep: `scripts/check-windows-footguns.py`
- Installer unit tests: `scripts/tests/test-install-ps1-*.ps1`
