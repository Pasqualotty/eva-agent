# EVA Agent — Messaging Gateway no Windows

Como deixar o **gateway de messaging** usável no Windows nativo: Telegram (caminho mais comum), outras plataformas, DM pairing e checklist do que **só você** preenche (tokens da UI).

CLI primária: **`eva`**. Alias histórico: **`hermes`** (mesmos subcomandos).

Home de dados no Windows: **`%LOCALAPPDATA%\eva`** (env interno ainda se chama `HERMES_HOME`).

Pré-requisito: install local (ver [install-windows.md](./install-windows.md)) + provider de modelo (`eva setup`).

---

## O que é o gateway

Processo de fundo que conecta a EVA a apps de mensagem (Telegram, Discord, Slack, WhatsApp, …). Uma instância por perfil; sessions, cron e delivery rodam no mesmo processo.

| Comando | Uso |
|---------|-----|
| `eva gateway setup` | Wizard interativo (plataformas, tokens, allowlist) |
| `eva gateway run` | Foreground (logs no terminal; bom para primeiro teste) |
| `eva gateway` | Atalho para run em foreground (conforme CLI) |
| `eva gateway install` | Auto-start no login (Scheduled Task; fallback Startup folder) |
| `eva gateway start` / `stop` / `restart` | Controlar o serviço Windows |
| `eva gateway status` | Status + PIDs + se o auto-start está instalado |
| `eva pairing …` | Aprovar/revogar usuários via código de pairing |

Docs longas de cada plataforma: `website/docs/user-guide/messaging/` (upstream Hermes; comandos `hermes` = `eva` neste fork).

---

## Caminhos importantes (Windows)

| Path | Conteúdo |
|------|----------|
| `%LOCALAPPDATA%\eva\.env` | **Secrets** (bot tokens, allowlists) — nunca commitar |
| `%LOCALAPPDATA%\eva\config.yaml` | Settings de comportamento (não secrets) |
| `%LOCALAPPDATA%\eva\logs\gateway.log` | Log principal do gateway |
| `%LOCALAPPDATA%\eva\logs\gateway-stdio.log` | stdout/stderr do launch detachado |
| `%LOCALAPPDATA%\eva\pairing\` | Estado de DM pairing |

Template sem secrets no repo: [gateway.env.example](./gateway.env.example).

---

## Fluxo rápido (Telegram)

### 1. Modelo / provider

```powershell
eva setup
# ou: eva setup --portal   # se usar Nous Portal
```

Sem model provider configurado o bot sobe, mas as respostas falham.

### 2. Criar o bot (só humano — UI Telegram)

1. Abra [@BotFather](https://t.me/BotFather) no Telegram.
2. `/newbot` → nome de exibição + username (deve terminar em `bot`).
3. **Copie o token** (`123456789:AA…`). Não cole em chat público, issue ou commit.
4. Opcional: `/setcommands`, `/setuserpic`, privacy de grupo (`/mybots` → Group Privacy).

### 3. Seu user ID numérico

O allowlist usa **ID numérico**, não `@username`.

- [@userinfobot](https://t.me/userinfobot) ou [@get_id_bot](https://t.me/get_id_bot)

### 4. Configurar o gateway

**Opção A — wizard (recomendado)**

```powershell
eva gateway setup
```

Escolha Telegram; cole o token e o user ID quando pedido. O wizard grava em `%LOCALAPPDATA%\eva\.env`.

**Opção B — manual**

1. Copie o template:

```powershell
# PowerShell
$homeEva = Join-Path $env:LOCALAPPDATA "eva"
New-Item -ItemType Directory -Force -Path $homeEva | Out-Null
Copy-Item .\docs\gateway.env.example (Join-Path $homeEva ".env") -ErrorAction SilentlyContinue
# Se .env já existir, edite em vez de sobrescrever.
notepad (Join-Path $homeEva ".env")
```

2. Preencha (exemplo — valores fictícios):

```env
TELEGRAM_BOT_TOKEN=REPLACE_WITH_BOTFATHER_TOKEN
TELEGRAM_ALLOWED_USERS=REPLACE_WITH_YOUR_NUMERIC_USER_ID
```

3. Nunca commite esse arquivo. O template do repo só tem placeholders.

### 5. Subir e testar

```powershell
# Primeiro teste: foreground (Ctrl+C para parar)
eva gateway run

# Em outro terminal / depois de validar:
eva gateway install   # auto-start no login
eva gateway start
eva gateway status
```

No Telegram, abra o bot e envie uma mensagem. Se a allowlist estiver certa, a EVA responde.

Logs:

```powershell
Get-Content "$env:LOCALAPPDATA\eva\logs\gateway.log" -Tail 80 -Wait
```

---

## DM pairing (autorizar outras pessoas)

Sem `GATEWAY_ALLOW_ALL_USERS=true` (não use em prod casual), só entra quem está:

1. na allowlist da plataforma (`TELEGRAM_ALLOWED_USERS`, …), ou  
2. aprovado via **pairing**.

Fluxo típico:

1. Usuário não autorizado manda DM ao bot → recebe (ou o log mostra) um **código de pairing**.
2. Você (dono) aprova no PC:

```powershell
eva pairing list
eva pairing approve telegram <CODE>
# revogar:
eva pairing revoke telegram <USER_ID>
eva pairing clear-pending
```

Ordem de auth no gateway (resumida): allow-all por plataforma → lista de pairing aprovada → allowlist da plataforma → allowlist global → `GATEWAY_ALLOW_ALL_USERS` → **deny**.

Detalhes: `website/docs/user-guide/security.md` (seção User Authorization).

---

## Outras plataformas (resumo)

Configure via `eva gateway setup` ou variáveis em `.env`. Cada uma exige **credenciais da UI do provedor** (você copia; a EVA não inventa).

| Plataforma | Vars mínimas (placeholders) | Onde pegar |
|------------|-----------------------------|------------|
| Telegram | `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS` | @BotFather |
| Discord | `DISCORD_BOT_TOKEN`, `DISCORD_ALLOWED_USERS` | Discord Developer Portal |
| Slack | `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_ALLOWED_USERS` | api.slack.com/apps |
| WhatsApp | `WHATSAPP_ENABLED=true` + allowlist | `eva whatsapp` (pair QR) |
| Outras | ver `.env.example` na raiz + `website/docs/user-guide/messaging/` | UI de cada serviço |

SDKs de messaging: no Windows o install/bootstrap costuma instalar deps se a var do token já estiver no `.env`. Se faltar import, rode o install de novo ou `eva doctor`.

---

## Serviço Windows (login + restart)

```powershell
eva gateway install      # Scheduled Task ONLOGON (sem admin em muitos PCs)
                         # se Access Denied → UAC ou fallback pasta Startup
eva gateway start
eva gateway status
eva gateway stop
eva gateway uninstall    # remove task + startup entry
```

- Task name padrão (compat): `Hermes_Gateway` (identificador interno; descrição: EVA Agent Gateway).
- Processos “órfãos” em foreground: `eva gateway stop` ou encerre o terminal do `run`.
- Após update do agent: `eva gateway restart` (ou `install` de novo se o launcher quebrou).

---

## Checklist — o que a EVA faz vs o que só você faz

### ✅ Automatizável / já documentado no repo

- [x] Docs Windows + template `.env` sem secrets  
- [x] Comandos `eva gateway` / alias `hermes`  
- [x] Paths `%LOCALAPPDATA%\eva`  
- [x] Pairing CLI (`eva pairing`)  
- [x] Install como Scheduled Task / Startup  

### ⏳ Só você (humano / UI)

1. **Telegram:** criar bot no @BotFather e copiar `TELEGRAM_BOT_TOKEN`  
2. **Seu user ID** numérico (userinfobot) → `TELEGRAM_ALLOWED_USERS`  
3. **Provider de modelo** (API key ou OAuth) se ainda não rodou `eva setup`  
4. **Discord/Slack/…:** tokens nas respectivas UIs (se for usar)  
5. **Aprovar pairing** de amigos (`eva pairing approve …`) quando alguém novo mandar DM  

Cole os valores no `%LOCALAPPDATA%\eva\.env` ou no wizard — **nunca** no git.

---

## Troubleshooting rápido

| Sintoma | O que checar |
|---------|----------------|
| Bot não responde | `eva gateway status`; token no `.env`; allowlist / pairing |
| “unauthorized” / silêncio | ID numérico errado; `eva pairing list` |
| Sobe e morre | `logs\gateway.log`; model provider; `eva doctor` |
| Duplicado / porta | `eva gateway stop` depois `start` |
| UAC no install | Aprovar, ou aceitar fallback Startup; ou `eva gateway run` só em foreground |
| Grupo não vê mensagens | BotFather Group Privacy OFF **e** re-add do bot no grupo |

---

## Segurança

- `.env` = secrets only. `config.yaml` = flags/timeouts/comportamento.  
- Não use `GATEWAY_ALLOW_ALL_USERS=true` a menos que entenda o risco (bot público).  
- Se o token vazar: `/revoke` no BotFather e gere outro.  
- Este repositório **não** deve conter tokens reais.

---

## Referências no tree

| Artefato | Path |
|----------|------|
| Template env (placeholders) | [docs/gateway.env.example](./gateway.env.example) |
| Install Windows | [docs/install-windows.md](./install-windows.md) |
| `.env.example` completo (raiz) | [../.env.example](../.env.example) |
| Adapter Telegram | `plugins/platforms/telegram/` |
| Pairing | `gateway/pairing.py`, `hermes_cli/pairing.py` |
| Windows service backend | `hermes_cli/gateway_windows.py` |
