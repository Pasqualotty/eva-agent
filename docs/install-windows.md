# EVA Agent Ã¢â‚¬â€ Windows install (do zero ao `eva` no PATH)

Guia para Windows 10/11. **Sem administrador** (mesmo modelo do Hermes): dados e tools em `%LOCALAPPDATA%\eva`, PATH no escopo do **usuÃƒÂ¡rio**.

| Caminho | Quando usar |
|---------|-------------|
| **A Ã¢â‚¬â€ Instalador gerenciado** | Uso diÃƒÂ¡rio; `eva` no PATH; Git/Node/uv portÃƒÂ¡teis se faltar |
| **B Ã¢â‚¬â€ Clone + bootstrap dev** | Desenvolvimento no repo; venv local `.venv` |
| **C Ã¢â‚¬â€ Docker Desktop** | Isolamento total |

---

## PrÃƒÂ©-requisitos

- Windows 10/11
- PowerShell **5.1+** (Windows PowerShell ou PowerShell 7+)
- Para o caminho **B**: Python **3.11Ã¢â‚¬â€œ3.13** no PATH (`python` / `py -3`)  
  Download: https://www.python.org/downloads/ Ã¢â‚¬â€ marque **Add python.exe to PATH**  
  Ou: `winget install Python.Python.3.12`

---

## Layout

| Path | Purpose |
|------|---------|
| `%LOCALAPPDATA%\eva` | Data home (`EVA_HOME` / `HERMES_HOME` Ã¢â‚¬â€ engine ainda aceita o alias Hermes) |
| `%LOCALAPPDATA%\eva\eva-agent` | Checkout gerenciado pelo instalador |
| `%LOCALAPPDATA%\eva\bin` | `uv` gerenciado |
| `%LOCALAPPDATA%\eva\git` | Portable Git Bash (se nÃƒÂ£o houver Git de sistema) |
| `%LOCALAPPDATA%\eva\node` | Portable Node (quando necessÃƒÂ¡rio) |
| `<repo>\.venv` | SÃƒÂ³ no caminho **B** (dev local; **nÃƒÂ£o** commitar) |

Override de home (qualquer caminho):

```powershell
$env:EVA_HOME = "D:\eva-data"   # preferido
$env:HERMES_HOME = "D:\eva-data"  # alias compat
```

---

## A Ã¢â‚¬â€ One-liner (instalaÃƒÂ§ÃƒÂ£o de usuÃƒÂ¡rio)

```powershell
iex (irm https://raw.githubusercontent.com/Pasqualotty/eva-agent/main/scripts/install.ps1)
```

CMD:

```bat
curl -fsSL https://raw.githubusercontent.com/Pasqualotty/eva-agent/main/scripts/install.cmd -o install.cmd && install.cmd && del install.cmd
```

OpÃƒÂ§ÃƒÂµes ÃƒÂºteis (download local do script):

```powershell
.\scripts\install.ps1 -SkipSetup
.\scripts\install.ps1 -Branch main
.\scripts\install.ps1 -HermesHome "D:\eva-data"
```

O instalador:

1. Clona/atualiza o repo em `%LOCALAPPDATA%\eva\eva-agent`
2. Cria venv + instala deps com `uv`/pip
3. Coloca `eva` (e alias `hermes`) no **user PATH**
4. Define `EVA_HOME` e `HERMES_HOME` no ambiente do usuÃƒÂ¡rio

Depois, abra um **novo** terminal:

```powershell
eva --help
eva setup
eva
```

Se `eva` nÃƒÂ£o for encontrado mas `hermes` funcionar, feche e reabra o terminal (PATH) ou rode o instalador de novo (ele grava `eva.cmd` ao lado de `hermes.exe` se o entry point faltar).

Se `eva` nÃ£o for encontrado mas `hermes` funcionar, feche e reabra o terminal (PATH) ou rode o instalador de novo (ele grava `eva.cmd` ao lado de `hermes.exe` se o entry point faltar).

---

## B â€” Clone local + bootstrap de desenvolvimento

Para trabalhar no cÃ³digo sem o layout gerenciado:

```powershell
git clone https://github.com/Pasqualotty/eva-agent.git
cd eva-agent

# Cria .venv, pip install -e ".[cli]", verifica eva --help
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\bootstrap_dev.ps1
```

Ativar o venv na sessÃ£o:

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
| `-Extras "cli"` | Default â€” extra mÃ­nimo (`simple-term-menu`) + deps core |
| `-Extras "cli,mcp,web"` | Extras adicionais (vÃ­rgula) |
| `-Extras ""` | SÃ³ deps core (`pip install -e .`) |
| `-Recreate` | Apaga e recria `.venv` |
| `-SkipVerify` | Instala sem checar `--help` |
| `-SetUserEnv` | Grava `EVA_HOME`/`HERMES_HOME` no ambiente do usuÃ¡rio |
| `-NoUv` | ForÃ§a stdlib venv + pip (ignora `uv` se existir) |

### Se faltar Python

O script **sai com mensagem clara** (exit 1) e aponta para python.org / winget / instalador A. NÃ£o tenta adivinhar.

### Unix-like no mesmo clone

Git Bash / WSL / macOS / Linux:

```bash
./setup-hermes.sh
```

---

## C â€” Docker Desktop

```powershell
docker compose -f docker-compose.windows.yml up -d --build
```

Monta `%LOCALAPPDATA%\eva` Ã¢â€ â€™ `/opt/data` no container.

---

## Checklist pÃƒÂ³s-install

- [ ] `eva --help` imprime help (ou `.venv\Scripts\eva.exe --help` no caminho B)
- [ ] Home de dados existe: `%LOCALAPPDATA%\eva`
- [ ] (Opcional) `eva setup` para provider / API keys em `.env` **sÃƒÂ³ secrets**
- [ ] Smoke leve (sem APIs pagas):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke_eva_windows.ps1
```

---

## Troubleshooting

| Sintoma | O que fazer |
|---------|-------------|
| `python` abre a Microsoft Store | Desative aliases em *Settings Ã¢â€ â€™ Apps Ã¢â€ â€™ Advanced app settings Ã¢â€ â€™ App execution aliases*, ou use o Python do python.org |
| `eva` nÃƒÂ£o encontrado apÃƒÂ³s A | Novo terminal; confira user PATH tem `%LOCALAPPDATA%\eva\eva-agent\.venv\Scripts` (ou o bin que o instalador reportou) |
| Build wheel / C compiler | Prefira Python 3.11Ã¢â‚¬â€œ3.12 com wheels; ou instale Build Tools. Extra `matrix` **nÃƒÂ£o** ÃƒÂ© default no Windows |
| Quer sÃƒÂ³ help, sem wizard | `eva --help` / bootstrap com `-SkipVerify` se a rede falhar no meio |
| PATH limpo / CI | Use caminho absoluto: `.\.venv\Scripts\eva.exe` |

---

## CLI e branding

- Entry points em `pyproject.toml`: `eva`, `eva-agent`, `eva-acp` (aliases `hermes*`)
- Repo canÃƒÂ´nico: https://github.com/Pasqualotty/eva-agent  
- Engine: este tree **ÃƒÂ©** o agent (fork MIT de Nous Hermes Ã¢â‚¬â€ ver `LICENSE` + `NOTICE`)

---

## Relacionados

- `scripts/bootstrap_dev.ps1` Ã¢â‚¬â€ dev local (este doc, caminho B)
- `scripts/install.ps1` / `install.cmd` Ã¢â‚¬â€ instalador gerenciado (caminho A)
- `scripts/smoke_eva_windows.ps1` Ã¢â‚¬â€ checks leves Windows
- `setup-hermes.sh` Ã¢â‚¬â€ bootstrap POSIX no clone
- Testes do instalador: `scripts/tests/test-install-ps1-*.ps1`
