# EVA Agent — Windows install (PowerShell)

User-scoped install. **No administrator rights required** (same model as upstream Hermes): tools land under `%LOCALAPPDATA%\eva`, PATH is the **user** PATH.

## One-liner

```powershell
iex (irm https://raw.githubusercontent.com/Pasqualotty/eva-agent/main/scripts/install.ps1)
```

CMD wrapper:

```bat
curl -fsSL https://raw.githubusercontent.com/Pasqualotty/eva-agent/main/scripts/install.cmd -o install.cmd && install.cmd && del install.cmd
```

## Layout

| Path | Purpose |
|------|---------|
| `%LOCALAPPDATA%\eva` | Data home (`HERMES_HOME` env — engine still uses this name) |
| `%LOCALAPPDATA%\eva\eva-agent` | Git checkout + venv |
| `%LOCALAPPDATA%\eva\bin` | Managed `uv` |
| `%LOCALAPPDATA%\eva\git` | Portable Git Bash (no system Git / no admin) |
| `%LOCALAPPDATA%\eva\node` | Portable Node (when needed) |

Override home:

```powershell
$env:HERMES_HOME = "D:\eva-data"
.\scripts\install.ps1
```

## Local clone (dev)

```powershell
git clone https://github.com/Pasqualotty/eva-agent.git
cd eva-agent
# Git Bash / WSL:
./setup-hermes.sh
# Or re-run the Windows installer against this tree via existing checkout updates.
```

## CLI

After install, open a **new** terminal:

```powershell
eva setup
eva
```

If `eva` is missing but `hermes` works, re-run the installer (it writes `eva.cmd` next to `hermes.exe`) or use `hermes` until the `eva` entry point lands in `pyproject.toml`.

## Docker Desktop (Windows)

```powershell
docker compose -f docker-compose.windows.yml up -d --build
```

Binds `%LOCALAPPDATA%\eva` → `/opt/data` in the container.

## License

MIT — Copyright (c) 2025 Nous Research. See root `LICENSE` and `NOTICE`.
