<p align="center">
  <img src="assets/banner.png" alt="EVA Agent" width="100%">
</p>

# EVA Agent

<p align="center">
  <a href="https://github.com/Pasqualotty/eva-agent"><img src="https://img.shields.io/badge/GitHub-Pasqualotty%2Feva--agent-181717?style=for-the-badge&logo=github" alt="GitHub"></a>
  <a href="https://github.com/Pasqualotty/eva-agent/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License: MIT"></a>
  <a href="README.md"><img src="https://img.shields.io/badge/Lang-English-blue?style=for-the-badge" alt="English"></a>
  <a href="#português"><img src="https://img.shields.io/badge/Lang-Português-green?style=for-the-badge" alt="Português"></a>
  <a href="README.zh-CN.md"><img src="https://img.shields.io/badge/Lang-中文-red?style=for-the-badge" alt="中文"></a>
  <a href="README.es.md"><img src="https://img.shields.io/badge/Lang-Español-orange?style=for-the-badge" alt="Español"></a>
  <a href="README.ur-pk.md"><img src="https://img.shields.io/badge/Lang-اردو-green?style=for-the-badge" alt="اردو"></a>
</p>

**EVA Agent** is a complete, self-improving personal AI agent — **skills, memory, messaging gateway, cron, tools, TUI, and desktop** — under its own brand.

This repository **is the engine**. It is a maintained fork of [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) (MIT). EVA does **not** install Hermes as an external dependency; every Hermes capability lives here as **EVA** product surface.

| | |
| --- | --- |
| **Canonical repo** | [github.com/Pasqualotty/eva-agent](https://github.com/Pasqualotty/eva-agent) |
| **CLI** | `eva` |
| **Windows home** | `%LOCALAPPDATA%\eva` |
| **Linux / macOS home** | `~/.eva` (profile-aware; see setup docs) |
| **License** | MIT — copyright retained for Nous Research in [LICENSE](LICENSE) |
| **Upstream** | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) |

It's the only agent with a built-in learning loop — it creates skills from experience, improves them during use, nudges itself to persist knowledge, searches its own past conversations, and builds a deepening model of who you are across sessions. Run it on a $5 VPS, a GPU cluster, or serverless infrastructure that costs nearly nothing when idle. Talk to it from Telegram while it works on a cloud VM.

Use any model you want — [Nous Portal](https://portal.nousresearch.com), OpenRouter, OpenAI, your own endpoint, and many others. Switch with `eva model` — no code changes, no lock-in.

<table>
<tr><td><b>A real terminal interface</b></td><td>Full TUI with multiline editing, slash-command autocomplete, conversation history, interrupt-and-redirect, and streaming tool output.</td></tr>
<tr><td><b>Lives where you do</b></td><td>Telegram, Discord, Slack, WhatsApp, Signal, and CLI — all from a single gateway process. Voice memo transcription, cross-platform conversation continuity.</td></tr>
<tr><td><b>A closed learning loop</b></td><td>Agent-curated memory with periodic nudges. Autonomous skill creation after complex tasks. Skills self-improve during use. FTS5 session search with LLM summarization for cross-session recall. <a href="https://github.com/plastic-labs/honcho">Honcho</a> dialectic user modeling. Compatible with the <a href="https://agentskills.io">agentskills.io</a> open standard.</td></tr>
<tr><td><b>Scheduled automations</b></td><td>Built-in cron scheduler with delivery to any platform. Daily reports, nightly backups, weekly audits — all in natural language, running unattended.</td></tr>
<tr><td><b>Delegates and parallelizes</b></td><td>Spawn isolated subagents for parallel workstreams. Write Python scripts that call tools via RPC, collapsing multi-step pipelines into zero-context-cost turns.</td></tr>
<tr><td><b>Runs anywhere, not just your laptop</b></td><td>Six terminal backends — local, Docker, SSH, Singularity, Modal, and Daytona. Daytona and Modal offer serverless persistence — your agent's environment hibernates when idle and wakes on demand, costing nearly nothing between sessions. Run it on a $5 VPS or a GPU cluster.</td></tr>
<tr><td><b>Research-ready</b></td><td>Batch trajectory generation, trajectory compression for training the next generation of tool-calling models.</td></tr>
<tr><td><b>Plugins & skills at the edges</b></td><td>Extend primarily through plugins and skills — not by growing the core tool schema. MCP catalog, memory providers, model providers, and platform adapters.</td></tr>
</table>

---

## Origin & credits

EVA Agent is a **fork** of **Hermes Agent** by [Nous Research](https://nousresearch.com), released under the **MIT License**.

- Upstream project: [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
- This product brand, packaging, Windows home (`%LOCALAPPDATA%\eva`), and CLI name (`eva`) are EVA-specific.
- LICENSE / copyright notices from Nous Research are **preserved**. Do not remove attribution.
- Internal module paths may still use `hermes_*` names (historical package layout). That is the engine code — not a second product dependency.

---

## Quick install

### From the canonical EVA repo (recommended)

```bash
git clone https://github.com/Pasqualotty/eva-agent.git
cd eva-agent
# Prefer uv; see CONTRIBUTING.md for the full dev layout
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv --python 3.11
# Linux/macOS:
source .venv/bin/activate
# Windows PowerShell: .\.venv\Scripts\Activate.ps1
uv pip install -e ".[all]"
eva              # start chatting (product CLI)
```

### Linux, macOS, WSL2, Termux (installer scripts)

Installer one-liners and managed layouts continue to evolve with the fork. Prefer cloning this repo until EVA-branded install URLs are published. Upstream Hermes install docs remain useful background for layout concepts.

> **Windows (native):** Target home is **`%LOCALAPPDATA%\eva`**. CLI, gateway, TUI, and tools are intended to work natively without WSL. WSL2 also works for a Linux-style home. Found a bug? Please [file issues](https://github.com/Pasqualotty/eva-agent/issues).

> **Android / Termux:** Use a curated `.[termux]` extra when the full `.[all]` set pulls Android-incompatible voice deps — same engine constraints as upstream.

After installation:

```bash
eva              # Interactive CLI
eva model        # Choose provider and model
eva tools        # Configure tools
eva gateway      # Messaging gateway (Telegram, Discord, …)
eva setup        # Full setup wizard
eva doctor       # Diagnose issues
eva update       # Update (when managed install is configured)
```

### Troubleshooting (Windows antivirus + `uv.exe`)

If antivirus quarantines `uv.exe` under the EVA bin folder (`%LOCALAPPDATA%\eva\bin\uv.exe`), this is typically a **false positive** on Astral's `uv` (Rust package manager). Whitelist the **folder**, not a single hash — `uv` updates change the hash every version.

```powershell
# Windows Defender (Admin)
Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\eva\bin"
```

See upstream Astral reports if needed: [astral-sh/uv#13553](https://github.com/astral-sh/uv/issues/13553).

---

## Getting started

```bash
eva              # Interactive CLI — start a conversation
eva model        # Choose your LLM provider and model
eva tools        # Configure which tools are enabled
eva config set   # Set individual config values
eva config get   # Print individual config values
eva gateway      # Start the messaging gateway
eva setup        # Run the full setup wizard
eva claw migrate # Migrate from OpenClaw (if coming from OpenClaw)
eva doctor       # Diagnose any issues
```

Docs site (Docusaurus in `website/`) ships with this repo. Build and serve locally with the website package when you need offline docs.

---

## Skip the API-key collection — Nous Portal

EVA works with whatever provider you want. If you'd rather not collect five separate API keys for the model, web search, image generation, TTS, and a cloud browser, **[Nous Portal](https://portal.nousresearch.com)** can cover them under one subscription:

- **300+ models** — pick with `/model <name>`
- **Tool Gateway** — web search, image generation, TTS, cloud browser routed through the sub

```bash
eva setup --portal
```

You can still bring your own keys per-tool — the gateway is per-backend, not all-or-nothing.

---

## CLI vs messaging quick reference

EVA has two entry points: start the terminal UI with `eva`, or run the gateway and talk from Telegram, Discord, Slack, WhatsApp, Signal, or Email. Many slash commands are shared.

| Action                         | CLI                                           | Messaging platforms                                                              |
| ------------------------------ | --------------------------------------------- | -------------------------------------------------------------------------------- |
| Start chatting                 | `eva`                                         | Run `eva gateway setup` + `eva gateway start`, then message the bot              |
| Start fresh conversation       | `/new` or `/reset`                            | `/new` or `/reset`                                                               |
| Change model                   | `/model [provider:model]`                     | `/model [provider:model]`                                                        |
| Set a personality              | `/personality [name]`                         | `/personality [name]`                                                            |
| Retry or undo the last turn    | `/retry`, `/undo`                             | `/retry`, `/undo`                                                                |
| Compress context / check usage | `/compress`, `/usage`, `/insights [--days N]` | `/compress`, `/usage`, `/insights [days]`                                        |
| Browse skills                  | `/skills` or `/<skill-name>`                  | `/<skill-name>`                                                                  |
| Interrupt current work         | `Ctrl+C` or send a new message                | `/stop` or send a new message                                                    |
| Platform-specific status       | `/platforms`                                  | `/status`, `/sethome`                                                            |

---

## Documentation map

| Topic | In-repo / guide |
| ----- | --------------- |
| Architecture & contribution rubric | [AGENTS.md](AGENTS.md) |
| Contributing (dev setup, PR priorities) | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Full docs site | `website/` (Docusaurus) |
| Security policy | [SECURITY.md](SECURITY.md) |
| License | [LICENSE](LICENSE) |

Feature areas (all first-class in EVA):

| Feature | What it covers |
| ------- | -------------- |
| CLI / TUI / Desktop | Terminal UI, Ink TUI, Electron app |
| Messaging gateway | 20+ platforms from one process |
| Tools & toolsets | Terminal, browser, vision, TTS, MCP, … |
| Skills | Procedural memory, Skills Hub, optional-skills |
| Memory | Persistent memory + pluggable providers |
| Cron | Scheduled jobs with multi-platform delivery |
| Delegation | Subagents, parallel batch tasks |
| Kanban | Multi-agent work queue |
| Plugins | Memory, model providers, platforms, context engines |
| Security | Approvals, pairing, isolation, secret sources |

---

## Migrating from OpenClaw

If you're coming from OpenClaw, EVA can import settings, memories, skills, and API keys (same migration path as the Hermes engine).

```bash
eva claw migrate              # Interactive migration (full preset)
eva claw migrate --dry-run    # Preview what would be migrated
eva claw migrate --preset user-data   # Migrate without secrets
eva claw migrate --overwrite  # Overwrite existing conflicts
```

What gets imported:

- **SOUL.md** — persona file
- **Memories** — MEMORY.md and USER.md entries
- **Skills** — user-created skills
- **Command allowlist** — approval patterns
- **Messaging settings** — platform configs, allowed users, working directory
- **API keys** — allowlisted secrets
- **TTS assets** — workspace audio files
- **Workspace instructions** — AGENTS.md (with `--workspace-target`)

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md).

```bash
git clone https://github.com/Pasqualotty/eva-agent.git
cd eva-agent
uv venv --python 3.11
source .venv/bin/activate   # Windows: .\.venv\Scripts\Activate.ps1
uv pip install -e ".[all,dev]"
scripts/run_tests.sh
```

Please keep PRs focused. Prefer extending skills/plugins over growing the core tool schema. See the contribution rubric in AGENTS.md.

---

## Community

- 🐛 [Issues](https://github.com/Pasqualotty/eva-agent/issues)
- 📦 [Source](https://github.com/Pasqualotty/eva-agent)
- 📚 [Skills Hub](https://agentskills.io) (open standard)
- Upstream community: [Nous Research Discord](https://discord.gg/NousResearch) · [Hermes upstream](https://github.com/NousResearch/hermes-agent)

---

## License

MIT — see [LICENSE](LICENSE).

Copyright (c) 2025 Nous Research (upstream). EVA Agent packaging and brand: maintained at [Pasqualotty/eva-agent](https://github.com/Pasqualotty/eva-agent).

---

<a id="português"></a>

## Português

**EVA Agent** é um agente de IA pessoal completo — **skills, memória, gateway de mensagens, cron, tools, TUI e desktop** — com marca própria.

Este repositório **é o motor** (fork MIT de [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)). Não se instala Hermes como dependência externa: todos os recursos do motor vivem aqui como **EVA**.

| | |
| --- | --- |
| **Repo canônico** | [github.com/Pasqualotty/eva-agent](https://github.com/Pasqualotty/eva-agent) |
| **CLI** | `eva` |
| **Home no Windows** | `%LOCALAPPDATA%\eva` |
| **Licença** | MIT (créditos Nous Research no LICENSE) |

### Instalação rápida

```bash
git clone https://github.com/Pasqualotty/eva-agent.git
cd eva-agent
uv venv --python 3.11
# PowerShell: .\.venv\Scripts\Activate.ps1
uv pip install -e ".[all]"
eva
```

### Comandos úteis

```bash
eva              # CLI interativo
eva model        # Provedor / modelo
eva tools        # Ferramentas
eva gateway      # Gateway (Telegram, Discord, …)
eva setup        # Assistente de configuração
eva doctor       # Diagnóstico
```

### Origem

Fork do Hermes Agent (Nous Research), MIT. Créditos e LICENSE do upstream são mantidos. Caminhos internos de código podem ainda usar nomes `hermes_*` — isso é layout histórico do pacote, não um segundo produto.

O restante deste README (features, migração OpenClaw, mapa de docs) vale em inglês e aplica-se integralmente ao EVA.
