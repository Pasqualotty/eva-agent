# EVA Agent — Windows smoke (manual + script)

Lightweight checks for the EVA Agent fork (Hermes-based) on Windows. No paid APIs, no real API keys.

## Prerequisites

- Windows 10/11
- PowerShell **5.1+** (Windows PowerShell or PowerShell 7+)
- Python **3.11–3.13** on PATH (`python`, `python3`, or `py -3`)

Optional (script **skips** if missing):

- `uv`
- Local venv (`.venv` or `venv`)
- Installed `hermes` / `eva` console scripts
- Full editable install (`pip install -e .` or `uv sync`)

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
| Repo layout markers | yes | `pyproject.toml`, `hermes_constants.py`, `toolsets.py`, `hermes_cli`, `skills`, … |
| Python available + version floor | yes | `>=3.11,<3.14` per `pyproject.toml` |
| `pyproject.toml` parse / scripts | yes | expects `hermes` → `hermes_cli.main` |
| `import hermes_constants` | yes | no third-party deps |
| Toolsets list | yes | `from toolsets import TOOLSETS` (no API keys) |
| Bundled skills | yes | counts `skills/**/SKILL.md` |
| LICENSE present | yes | NOTICE optional |
| `uv` / venv | no | SKIP if absent |
| `hermes --help` | no | SKIP if deps not installed |
| `eva --help` | no | SKIP until rebrand CLI exists |
| `hermes doctor` | no | only if CLI help already works |
| Windows footguns on core files | no | advisory |

Exit **0** when all required checks pass (skips are fine). Exit **1** on required failures. Exit **2** if the repo root cannot be found.

## Manual steps (if you prefer not to run the script)

1. Confirm Python:

   ```powershell
   python -c "import sys; print(sys.version); assert sys.version_info >= (3,11)"
   ```

2. Confirm repo imports without install:

   ```powershell
   python -c "import hermes_constants; print(hermes_constants.get_hermes_home())"
   python -c "from toolsets import TOOLSETS; print(len(TOOLSETS), sorted(TOOLSETS)[:8])"
   ```

3. After a full install (venv + deps):

   ```powershell
   hermes --help
   hermes doctor
   # when rebrand lands:
   eva --help
   ```

4. Do **not** run live model/provider calls in smoke — that needs real keys and is out of scope.

## Product notes (EVA fork)

- Canonical fork: https://github.com/Pasqualotty/eva-agent  
- Upstream engine: this repo **is** the agent (do not install Hermes as an external dependency).
- Target Windows home for EVA branding: `%LOCALAPPDATA%\eva` (Hermes default remains `%LOCALAPPDATA%\hermes` until rebrand identity ships).
- Keep Nous Research `LICENSE` / `NOTICE` intact.

## Related

- Installer: `scripts/install.ps1`
- Windows footgun grep: `scripts/check-windows-footguns.py`
- Installer unit tests: `scripts/tests/test-install-ps1-*.ps1`
