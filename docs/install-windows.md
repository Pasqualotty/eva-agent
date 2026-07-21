# EVA Agent — Windows install (do zero ao `eva` no PATH)

Guia para Windows 10/11. **Sem administrador** (mesmo modelo do Hermes): dados e tools em `%LOCALAPPDATA%\eva`, PATH no escopo do **usuário**.

| Caminho | Quando usar |
|---------|-------------|
| **A — Instalador gerenciado** | Uso diário; `eva` no PATH; Git/Node/uv portáteis se faltar |
| **B — Clone + bootstrap dev** | Desenvolvimento no repo; venv local `.venv` |
| **C — Docker Desktop** | Isolamento total |

---

## Pré-requisitos

- Windows 10/11
- PowerShell **5.1+** (Windows PowerShell ou PowerShell 7+)
- Para o caminho **B**: Python **3.11–3.13** no PATH (`python` / `py -3`)  
  Download: https://www.python.org/downloads/ — marque **Add python.exe to PATH**  
  Ou: `winget install Python.Python.3.12`

---

## Layout

| Path | Purpose |
|------|---------|
| `%LOCALAPPDATA%\eva` | Data home (`EVA_HOME` / `HERMES_HOME` — engine ainda aceita o alias Hermes) |
| `%LOCALAPPDATA%\eva\eva-agent` | Checkout gerenciado pelo instalador |
| `%LOCALAPPDATA%\eva\bin` | `uv` gerenciado |
| `%LOCALAPPDATA%\eva\git` | Portable Git Bash (se não houver Git de sistema) |
| `%LOCALAPPDATA%\eva\node` | Portable Node (quando necessário) |
| `<repo>\.venv` | Só no caminho **B** (dev local; **não** commitar) |

Override de home (qualquer caminho):

```powershell
$env:EVA_HOME = "D:\eva-data"   # preferido
$env:HERMES_HOME = "D:\eva-data"  # alias compat
```

---

## A — One-liner (instalação de usuário)

```powershell
iex (irm https://raw.githubusercontent.com/Pasqualotty/eva-agent/main/scripts/install.ps1)
```

CMD:

```bat
curl -fsSL https://raw.githubusercontent.com/Pasqualotty/eva-agent/main/scripts/install.cmd -o install.cmd && install.cmd && del install.cmd
```

Opções úteis (download local do script):

```powershell
.\scripts\install.ps1 -SkipSetup
.\scripts\install.ps1 -Branch main
.\scripts\install.ps1 -HermesHome "D:\eva-data"
```

O instalador:

1. Clona/atualiza o repo em `%LOCALAPPDATA%\eva\eva-agent`
2. Cria venv + instala deps com `uv`/pip
3. Coloca `eva` (e alias `hermes`) no **user PATH**
4. Define `EVA_HOME` e `HERMES_HOME` no ambiente do usuário

Depois, abra um **novo** terminal:

```powershell
eva --help
eva setup
eva
```

Se `eva` não for encontrado mas `hermes` funcionar, feche e reabra o terminal (PATH) ou rode o instalador de novo (ele grava `eva.cmd` ao lado de `hermes.exe` se o entry point faltar).

---

## B — Clone local + bootstrap de desenvolvimento

Para trabalhar no código sem o layout gerenciado:

```powershell
git clone https://github.com/Pasqualotty/eva-agent.git
cd eva-agent

# Cria .venv, pip install -e ".[cli]", verifica eva --help
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\bootstrap_dev.ps1
```

Ativar o venv na sessão:

```powershell
.\.venv\Scripts\Activate.ps1
eva --help
eva setup
```

Sem ativar:

```powershell
.\.venv\Scripts\eva.exe --help
.\.venv\Scripts\python.exe -m hermes_cli.main --help
```

### Flags do bootstrap

| Flag | Efeito |
|------|--------|
| `-Extras "cli"` | Default — extra mínimo (`simple-term-menu`) + deps core |
| `-Extras "cli,mcp,web"` | Extras adicionais (vírgula) |
| `-Extras ""` | Só deps core (`pip install -e .`) |
| `-Recreate` | Apaga e recria `.venv` |
| `-SkipVerify` | Instala sem checar `--help` |
| `-SetUserEnv` | Grava `EVA_HOME`/`HERMES_HOME` no ambiente do usuário |
| `-NoUv` | Força stdlib venv + pip (ignora `uv` se existir) |

### Se faltar Python

O script **sai com mensagem clara** (exit 1) e aponta para python.org / winget / instalador A. Não tenta adivinhar.

### Unix-like no mesmo clone

Git Bash / WSL / macOS / Linux:

```bash
./setup-hermes.sh
```

---

## C — Docker Desktop

```powershell
docker compose -f docker-compose.windows.yml up -d --build
```

Monta `%LOCALAPPDATA%\eva` → `/opt/data` no container.

---

## Checklist pós-install

- [ ] `eva --help` imprime help (ou `.venv\Scripts\eva.exe --help` no caminho B)
- [ ] Home de dados existe: `%LOCALAPPDATA%\eva`
- [ ] (Opcional) `eva setup` para provider / API keys em `.env` **só secrets**
- [ ] Smoke leve (sem APIs pagas):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke_eva_windows.ps1
```

---

## Troubleshooting

| Sintoma | O que fazer |
|---------|-------------|
| `python` abre a Microsoft Store | Desative aliases em *Settings → Apps → Advanced app settings → App execution aliases*, ou use o Python do python.org |
| `eva` não encontrado após A | Novo terminal; confira user PATH tem `%LOCALAPPDATA%\eva\eva-agent\.venv\Scripts` (ou o bin que o instalador reportou) |
| Build wheel / C compiler | Prefira Python 3.11–3.12 com wheels; ou instale Build Tools. Extra `matrix` **não** é default no Windows |
| Quer só help, sem wizard | `eva --help` / bootstrap com `-SkipVerify` se a rede falhar no meio |
| PATH limpo / CI | Use caminho absoluto: `.\.venv\Scripts\eva.exe` |

---

## CLI e branding

- Entry points em `pyproject.toml`: `eva`, `eva-agent`, `eva-acp` (aliases `hermes*`)
- Repo canônico: https://github.com/Pasqualotty/eva-agent  
- Engine: este tree **é** o agent (fork MIT de Nous Hermes — ver `LICENSE` + `NOTICE`)

---

## Relacionados

- `scripts/bootstrap_dev.ps1` — dev local (este doc, caminho B)
- `scripts/install.ps1` / `install.cmd` — instalador gerenciado (caminho A)
- `scripts/smoke_eva_windows.ps1` — checks leves Windows
- `setup-hermes.sh` — bootstrap POSIX no clone
- Testes do instalador: `scripts/tests/test-install-ps1-*.ps1`
