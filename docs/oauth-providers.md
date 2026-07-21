# Conectar providers via OAuth (sem API key)

A EVA (fork Hermes) **já suporta OAuth** para vários providers. Você não precisa só de API key.

## Resumo

| Provider | ID do comando | Tipo | O que precisa |
|----------|---------------|------|----------------|
| **xAI / Grok** | `xai-oauth` | OAuth device code (browser) | SuperGrok ou X Premium+ |
| **OpenAI Codex** | `openai-codex` | OAuth device code (browser) | Conta OpenAI com acesso Codex/ChatGPT pro coding |
| **OpenAI API clássica** | `openai-api` / env `OPENAI_API_KEY` | **só API key** | Chave em platform.openai.com |
| Nous Portal | `nous` | OAuth | Conta Nous |
| Anthropic | `anthropic` | OAuth ou key | Claude Pro/API |
| Qwen / MiniMax | `qwen-oauth` / `minimax-oauth` | OAuth | Contas respectivas |

Credenciais ficam em `%LOCALAPPDATA%\eva\` (auth store / `auth.json`) — **não** no git.

## Grok (xAI) via OAuth

```powershell
# Opção A — wizard de modelo (recomendado)
eva model
# escolha: "xAI Grok OAuth (SuperGrok / Premium+)"
# abra o link accounts.x.ai, digite o código, aprove

# Opção B — login direto
eva auth add xai-oauth --type oauth
```

Sem browser automático (SSH / remoto):

```powershell
eva auth add xai-oauth --type oauth --no-browser
# abra a URL impressa no navegador de outra máquina
```

Depois:

```powershell
eva auth status
eva
# ou escolha o provider de novo em: eva model
```

Doc completa (upstream): `website/docs/guides/xai-grok-oauth.md`

> **Nota:** se o login OAuth no browser ok mas a API retorna 403, a xAI às vezes restringe o surface OAuth por tier. Nesse caso use `XAI_API_KEY` (console.x.ai) com provider API key.

## OpenAI via OAuth (Codex)

O fluxo OAuth oficial no Hermes/EVA para OpenAI é o **OpenAI Codex** (device code em `auth.openai.com`), não a chave `sk-...` da API platform.

```powershell
eva auth add openai-codex --type oauth
# abra o browser, faça login na conta OpenAI, aprove o device code
eva model
# selecione OpenAI Codex e o modelo desejado
```

API key “clássica” (sem OAuth):

```powershell
eva auth add openai-api --type api-key
# ou no .env: OPENAI_API_KEY=sk-...
```

## Ver o que está logado

```powershell
eva auth list
eva auth status
eva auth logout          # se precisar limpar
```

## Fluxo “quero só OAuth no dia a dia”

1. `eva auth add xai-oauth --type oauth` → Grok  
2. `eva auth add openai-codex --type oauth` → OpenAI Codex  
3. `eva model` → marque o default (Grok OAuth ou Codex)  
4. `eva` → conversa  

Gateway Telegram e Desk usam o **mesmo** store de auth do core (`%LOCALAPPDATA%\eva`).

## Troubleshooting

| Sintoma | Ação |
|---------|------|
| Não abre browser | `--no-browser` e abra a URL manualmente |
| OAuth ok, chat 403 (xAI) | SuperGrok/Premium+ ativo? Fallback: API key |
| `auth list` vazio | Rodou `add` até “Saved/Added”? Veja pasta `%LOCALAPPDATA%\eva` |
| Quer trocar de conta | `eva auth logout` ou `eva auth remove` e login de novo |