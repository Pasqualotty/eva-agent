# EVA Parity Matrix — Hermes → EVA

Checklist de aceite de produto: **todas as capacidades do Hermes Agent** devem permanecer no fork EVA (`Pasqualotty/eva-agent`), com rebrand de marca/home/CLI, sem perder funcionalidade.

| Campo | Valor |
|-------|--------|
| **Repo canônico** | https://github.com/Pasqualotty/eva-agent |
| **Upstream** | Fork MIT de NousResearch/hermes-agent |
| **Baseline HEAD** | `477c08b` (fmt(js): `npm run fix` on merge) — worktree `feat/eva-parity-matrix` |
| **Objetivo produto** | Todos os recursos Hermes; marca EVA; home Windows `%LOCALAPPDATA%\eva`; CLI `eva` |
| **Licença** | MIT (Copyright Nous Research) — manter LICENSE; NOTICE se/quando adicionado |
| **Regra de motor** | Não instalar Hermes como dependência externa — este repo **já é** o motor |

## Como ler esta matriz

| Coluna | Significado |
|--------|-------------|
| **Feature** | Capacidade observável (produto ou superfície técnica) |
| **Status no fork** | Estado neste checkout. Baseline: *presente no fork Hermes (baseline)* até provar o contrário. |
| **Como validar** | Smoke / comando / caminho de código para provar presença |
| **Owner/frente** | Quem carrega o trabalho de paridade/rebrand (ou `baseline` se só inventário) |

### Status permitidos

| Status | Uso |
|--------|-----|
| `presente no fork Hermes (baseline)` | Código/docs existem no tree; rebrand EVA ainda não exigido ou não verificado |
| `presente (rebrand pendente)` | Feature ok; paths/strings ainda Hermes (`hermes`, `~/.hermes`, etc.) |
| `gap` | Removido ou quebrado no rebrand/fork — **preencher só com evidência** |
| `N/A EVA` | Decisão explícita de não portar (precisa OK de produto) |

**Gaps conhecidos:** nenhum (inventário inicial — nada removido por rebrand neste worktree).

**Owners / frentes maestro (referência):**

| Apelido | Escopo típico |
|---------|----------------|
| `parity-matrix` | Este doc |
| `docs-brand` | README, EVA-AGENT.md, branding docs |
| `identity-core` | `get_hermes_home` → home EVA, constants, profiles |
| `cli-entry` | Entry `eva` / `hermes` dual ou rename |
| `install-windows` | Installer PS1, `%LOCALAPPDATA%\eva` |
| `persona-defaults` | SOUL, skins, copy de agente |
| `smoke-windows` | Smoke nativo Windows |
| `baseline` | Sem frente dedicada ainda — inventário |

---

## 1. Agent loop

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| `AIAgent` core (`run_agent.py`) | presente no fork Hermes (baseline) | Import `run_agent.AIAgent`; loop em `run_conversation` | baseline |
| Conversation loop / tool iterations | presente no fork Hermes (baseline) | `agent/conversation_loop.py`; `max_iterations` + budget | baseline |
| Prompt caching (prefix estável) | presente no fork Hermes (baseline) | `agent/prompt_caching.py`; AGENTS.md “cache sacred” | baseline |
| Context compression | presente no fork Hermes (baseline) | `agent/context_compressor.py`, `conversation_compression.py` | baseline |
| System prompt builder | presente no fork Hermes (baseline) | `agent/system_prompt.py`, `prompt_builder.py` | baseline / persona-defaults |
| Iteration budget + grace call | presente no fork Hermes (baseline) | `agent/iteration_budget.py` | baseline |
| Tool executor / dispatch | presente no fork Hermes (baseline) | `agent/tool_executor.py`, `model_tools.handle_function_call` | baseline |
| Aux LLM tasks (title, vision, etc.) | presente no fork Hermes (baseline) | `agent/auxiliary_client.py` | baseline |
| MoA (mixture of agents) loop | presente no fork Hermes (baseline) | `agent/moa_loop.py`; `hermes moa` / config | baseline |
| Credential pool / fallback model | presente no fork Hermes (baseline) | `agent/credential_pool.py`; config `fallback` | baseline |
| Batch runner | presente no fork Hermes (baseline) | `batch_runner.py` | baseline |
| Oneshot mode | presente no fork Hermes (baseline) | `agent/oneshot.py`; `hermes_cli/oneshot.py` | baseline |
| Interrupt / stop mid-turn | presente no fork Hermes (baseline) | `tools/interrupt.py`; gateway `/stop` | baseline |

---

## 2. Tools / toolsets

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Registry + auto-discovery `tools/*.py` | presente no fork Hermes (baseline) | `tools/registry.py`; `model_tools.discover_builtin_tools` | baseline |
| `_HERMES_CORE_TOOLS` bundle | presente no fork Hermes (baseline) | `toolsets.py` L31–81 | baseline / cli-entry (rename later) |
| Toolset composition (`TOOLSETS`) | presente no fork Hermes (baseline) | `toolsets.py` keys: web, terminal, file, browser, … | baseline |
| `hermes tools` curses UI | presente no fork Hermes (baseline) | `hermes_cli/tools_config.py`; subcommand `tools` | cli-entry |
| Web: `web_search`, `web_extract` | presente no fork Hermes (baseline) | `tools/web_tools.py`; plugins `plugins/web/*` | baseline |
| X search (`x_search`) | presente no fork Hermes (baseline) | toolset `x_search`; `tools/x_search_tool.py` | baseline |
| File: read/write/patch/search | presente no fork Hermes (baseline) | `tools/file_tools.py`, `file_operations.py` | baseline |
| Terminal + process | presente no fork Hermes (baseline) | `tools/terminal_tool.py` | baseline |
| Code execution (`execute_code`) | presente no fork Hermes (baseline) | `tools/code_execution_tool.py` | baseline |
| Vision (`vision_analyze`) | presente no fork Hermes (baseline) | `tools/vision_tools.py` | baseline |
| Image gen | presente no fork Hermes (baseline) | `tools/image_generation_tool.py`; `plugins/image_gen/*` | baseline |
| Video analyze / video gen | presente no fork Hermes (baseline) | toolsets `video`, `video_gen`; `plugins/video_gen/*` | baseline |
| TTS (`text_to_speech`) | presente no fork Hermes (baseline) | `tools/tts_tool.py` | baseline |
| Todo | presente no fork Hermes (baseline) | `tools/todo_tool.py` | baseline |
| Clarify | presente no fork Hermes (baseline) | `tools/clarify_tool.py` | baseline |
| Computer use | presente no fork Hermes (baseline) | `tools/computer_use/` | baseline |
| Home Assistant tools | presente no fork Hermes (baseline) | `tools/homeassistant_tool.py` (gated `HASS_TOKEN`) | baseline |
| Discord / Discord admin tools | presente no fork Hermes (baseline) | `tools/discord_tool.py` | baseline |
| Feishu doc/drive tools | presente no fork Hermes (baseline) | `tools/feishu_*` | baseline |
| Spotify tools | presente no fork Hermes (baseline) | `plugins/spotify/` | baseline |
| Yuanbao tools | presente no fork Hermes (baseline) | `tools/yuanbao_tools.py` | baseline |
| Project tools (desktop GUI only) | presente no fork Hermes (baseline) | toolset `project`; `tools/project_tools.py` | baseline |
| Coding toolset posture | presente no fork Hermes (baseline) | toolset `coding`; `agent/coding_context.py` | baseline |
| Safe / webhook-constrained toolsets | presente no fork Hermes (baseline) | `_HERMES_WEBHOOK_SAFE_TOOLS`; toolset `safe` | baseline |
| Kanban tools | presente no fork Hermes (baseline) | `tools/kanban_tools.py` | baseline |
| Send message / messaging helpers | presente no fork Hermes (baseline) | `tools/send_message_tool.py` | baseline |
| Tool result storage / output limits | presente no fork Hermes (baseline) | `tools/tool_result_storage.py`, `tool_output_limits.py` | baseline |
| Tool search | presente no fork Hermes (baseline) | `tools/tool_search.py` | baseline |

---

## 3. Skills + hub

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Built-in skills tree (`skills/`) | presente no fork Hermes (baseline) | Categorias: github, mlops, productivity, creative, … | baseline |
| Optional skills (`optional-skills/`) | presente no fork Hermes (baseline) | Install via `hermes skills install official/...` | baseline |
| Skill tools: list/view/manage | presente no fork Hermes (baseline) | `tools/skills_tool.py`, `skill_manager_tool.py` | baseline |
| Skills hub | presente no fork Hermes (baseline) | `tools/skills_hub.py`; `hermes_cli/skills_hub.py` | baseline |
| Skill slash commands | presente no fork Hermes (baseline) | `agent/skill_commands.py` | baseline |
| Skill bundles | presente no fork Hermes (baseline) | `agent/skill_bundles.py`; `hermes_cli/bundles.py` | baseline |
| Skill guard / AST audit / provenance | presente no fork Hermes (baseline) | `tools/skills_guard.py`, `skills_ast_audit.py`, `skill_provenance.py` | baseline |
| Curator (lifecycle agent skills) | presente no fork Hermes (baseline) | `agent/curator.py`; `hermes curator` | baseline |
| Skill usage telemetry sidecar | presente no fork Hermes (baseline) | `tools/skill_usage.py` → `.usage.json` | baseline |
| agentskills.io compatible SKILL.md | presente no fork Hermes (baseline) | Frontmatter standards in AGENTS.md | baseline |
| Index caches (marketplace) | presente no fork Hermes (baseline) | `skills/index-cache/*.json` | baseline |

---

## 4. Memory + FTS5

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Built-in memory tool | presente no fork Hermes (baseline) | `tools/memory_tool.py` | baseline |
| Session DB SQLite (`hermes_state.py`) | presente no fork Hermes (baseline) | Sessions + messages tables | identity-core (path) |
| FTS5 full-text search | presente no fork Hermes (baseline) | `CREATE VIRTUAL TABLE messages_fts` in `hermes_state.py` | baseline |
| `session_search` tool | presente no fork Hermes (baseline) | `tools/session_search_tool.py` | baseline |
| Memory provider ABC + manager | presente no fork Hermes (baseline) | `agent/memory_provider.py`, `memory_manager.py` | baseline |
| Honcho provider | presente no fork Hermes (baseline) | `plugins/memory/honcho/` | baseline |
| Mem0 provider | presente no fork Hermes (baseline) | `plugins/memory/mem0/` | baseline |
| Supermemory provider | presente no fork Hermes (baseline) | `plugins/memory/supermemory/` | baseline |
| Hindsight / Holographic / OpenViking / RetainDB / Byterover | presente no fork Hermes (baseline) | `plugins/memory/*/` | baseline |
| `hermes memory` setup CLI | presente no fork Hermes (baseline) | `hermes_cli/memory_setup.py`; subcommand `memory` | cli-entry |
| Learning graph / mutations | presente no fork Hermes (baseline) | `agent/learning_graph.py`, `learning_mutations.py` | baseline |

---

## 5. Gateway messaging

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Gateway runner | presente no fork Hermes (baseline) | `gateway/run.py`; `hermes gateway` | baseline |
| Platform base adapter | presente no fork Hermes (baseline) | `gateway/platforms/base.py` | baseline |
| Telegram | presente no fork Hermes (baseline) | `plugins/platforms/telegram/` | baseline |
| Discord | presente no fork Hermes (baseline) | `plugins/platforms/discord/` | baseline |
| Slack | presente no fork Hermes (baseline) | `plugins/platforms/slack/` | baseline |
| WhatsApp (Baileys plugin + Cloud) | presente no fork Hermes (baseline) | `plugins/platforms/whatsapp/`; `gateway/platforms/whatsapp_cloud.py` | baseline |
| Signal | presente no fork Hermes (baseline) | `gateway/platforms/signal.py` | baseline |
| Matrix | presente no fork Hermes (baseline) | `plugins/platforms/matrix/` | baseline |
| Mattermost | presente no fork Hermes (baseline) | `plugins/platforms/mattermost/` | baseline |
| Email | presente no fork Hermes (baseline) | `plugins/platforms/email/` | baseline |
| SMS | presente no fork Hermes (baseline) | `plugins/platforms/sms/` | baseline |
| Home Assistant chat | presente no fork Hermes (baseline) | `plugins/platforms/homeassistant/` | baseline |
| DingTalk / WeCom / Weixin / Feishu / QQ / Yuanbao | presente no fork Hermes (baseline) | `plugins/platforms/*` + `gateway/platforms/*` | baseline |
| BlueBubbles / LINE / Teams / IRC / Google Chat / ntfy / Photon / Raft / Simplex | presente no fork Hermes (baseline) | `plugins/platforms/*` | baseline |
| Webhook + API server adapters | presente no fork Hermes (baseline) | `gateway/platforms/webhook.py`, `api_server.py` | baseline |
| MS Graph webhook | presente no fork Hermes (baseline) | `gateway/platforms/msgraph_webhook.py` | baseline |
| Pairing / allowlist | presente no fork Hermes (baseline) | `gateway/pairing.py`; `hermes pairing` | baseline |
| Delivery ledger / dead targets | presente no fork Hermes (baseline) | `gateway/delivery.py`, `dead_targets.py` | baseline |
| Stream dispatch / consumer | presente no fork Hermes (baseline) | `gateway/stream_*.py` | baseline |
| Slash commands in gateway | presente no fork Hermes (baseline) | `gateway/slash_commands.py`; registry em `hermes_cli/commands.py` | baseline |
| Profile routing | presente no fork Hermes (baseline) | `gateway/profile_routing.py`; `docs/profile-routing.md` | baseline |
| Kanban watchers in gateway | presente no fork Hermes (baseline) | `gateway/kanban_watchers.py` | baseline |
| Relay connector | presente no fork Hermes (baseline) | `gateway/relay/`; `docs/relay-connector-contract.md` | baseline |
| Windows gateway service helpers | presente no fork Hermes (baseline) | `hermes_cli/gateway_windows.py` | install-windows / smoke-windows |
| Session lifecycle | presente no fork Hermes (baseline) | `gateway/session.py`; `docs/session-lifecycle.md` | baseline |

---

## 6. Cron

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Job store | presente no fork Hermes (baseline) | `cron/jobs.py` | baseline |
| Scheduler tick loop | presente no fork Hermes (baseline) | `cron/scheduler.py`; file lock `.tick.lock` | baseline |
| Cron tool (`cronjob`) | presente no fork Hermes (baseline) | `tools/cronjob_tools.py` | baseline |
| CLI `hermes cron` | presente no fork Hermes (baseline) | `hermes_cli/cron.py`; subcommand | cli-entry |
| Schedule formats (duration, every, 5-field, ISO) | presente no fork Hermes (baseline) | Docs AGENTS.md + jobs parser | baseline |
| Executions / lifecycle guard | presente no fork Hermes (baseline) | `cron/executions.py`, `lifecycle_guard.py` | baseline |
| Suggestions / blueprints | presente no fork Hermes (baseline) | `cron/suggestions.py`, `blueprint_catalog.py` | baseline |
| Chronos managed provider | presente no fork Hermes (baseline) | `plugins/cron_providers/chronos/`; contract doc | baseline |
| Multi-platform delivery of job output | presente no fork Hermes (baseline) | scheduler delivery paths | baseline |

---

## 7. Subagents / delegation / kanban

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| `delegate_task` single | presente no fork Hermes (baseline) | `tools/delegate_tool.py` | baseline |
| Batch parallel children | presente no fork Hermes (baseline) | `tasks: [...]`; `delegation.max_concurrent_children` | baseline |
| Roles leaf / orchestrator | presente no fork Hermes (baseline) | `role=`; `max_spawn_depth` | baseline |
| Background async delegation | presente no fork Hermes (baseline) | `tools/async_delegation.py` | baseline |
| Live log for children | presente no fork Hermes (baseline) | `tools/delegation_live_log.py` | baseline |
| Kanban board SQLite | presente no fork Hermes (baseline) | `hermes_cli/kanban_db.py` | baseline |
| `hermes kanban` CLI verbs | presente no fork Hermes (baseline) | `hermes_cli/kanban.py` | cli-entry |
| Kanban dispatcher (in-gateway) | presente no fork Hermes (baseline) | `kanban.dispatch_in_gateway`; systemd unit in plugin | baseline |
| Kanban dashboard plugin | presente no fork Hermes (baseline) | `plugins/kanban/dashboard/` | baseline |
| Swarm / decompose helpers | presente no fork Hermes (baseline) | `hermes_cli/kanban_swarm.py`, `kanban_decompose.py` | baseline |

---

## 8. MCP

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| MCP client tool integration | presente no fork Hermes (baseline) | `tools/mcp_tool.py` | baseline |
| MCP OAuth | presente no fork Hermes (baseline) | `tools/mcp_oauth.py`, `mcp_oauth_manager.py` | baseline |
| MCP config / catalog / picker | presente no fork Hermes (baseline) | `hermes_cli/mcp_*.py` | baseline |
| `hermes mcp` subcommand | presente no fork Hermes (baseline) | `hermes_cli/subcommands/mcp.py` | cli-entry |
| MCP serve entry | presente no fork Hermes (baseline) | `mcp_serve.py` | baseline |
| MCP security | presente no fork Hermes (baseline) | `hermes_cli/mcp_security.py` | baseline |
| Optional MCP manifests | presente no fork Hermes (baseline) | `optional-mcps/{blender,linear,n8n,unreal-engine}/` | baseline |
| MCP stdio watchdog | presente no fork Hermes (baseline) | `tools/mcp_stdio_watchdog.py` | baseline |
| Dashboard OAuth for MCP | presente no fork Hermes (baseline) | `tools/mcp_dashboard_oauth.py` | baseline |

---

## 9. Providers (inference + aux)

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Provider plugin discovery | presente no fork Hermes (baseline) | `plugins/model-providers/`; `providers/` | baseline |
| OpenRouter | presente no fork Hermes (baseline) | `plugins/model-providers/openrouter/` | baseline |
| Anthropic | presente no fork Hermes (baseline) | `plugins/model-providers/anthropic/` | baseline |
| OpenAI Codex / Responses | presente no fork Hermes (baseline) | `openai-codex` plugin; `agent/codex_*` | baseline |
| Nous Portal | presente no fork Hermes (baseline) | `plugins/model-providers/nous/`; billing modules | baseline |
| Gemini / Vertex / Bedrock | presente no fork Hermes (baseline) | respective plugins + adapters | baseline |
| xAI / DeepSeek / Fireworks / Grok-related | presente no fork Hermes (baseline) | `xai`, `deepseek`, `fireworks`, … | baseline |
| Ollama cloud / HuggingFace / Nvidia / custom | presente no fork Hermes (baseline) | plugins list under `model-providers/` | baseline |
| Copilot / Copilot ACP | presente no fork Hermes (baseline) | `copilot`, `copilot-acp` plugins | baseline |
| `hermes model` switcher | presente no fork Hermes (baseline) | `hermes_cli/model_switch.py` | cli-entry |
| Runtime provider resolution | presente no fork Hermes (baseline) | `hermes_cli/runtime_provider.py` | baseline |
| Transports (chat completions, etc.) | presente no fork Hermes (baseline) | `agent/transports/` | baseline |
| Web search providers | presente no fork Hermes (baseline) | `plugins/web/*`; `agent/web_search_registry.py` | baseline |
| Image/video gen provider registries | presente no fork Hermes (baseline) | `agent/image_gen_registry.py`, `video_gen_registry.py` | baseline |
| TTS / STT registries | presente no fork Hermes (baseline) | `agent/tts_registry.py`, `transcription_registry.py` | baseline |

---

## 10. Context files

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| SOUL.md identity | presente no fork Hermes (baseline) | Load via prompt builder; `docker/SOUL.md`; `default_soul` | persona-defaults |
| AGENTS.md / CLAUDE.md / .cursorrules | presente no fork Hermes (baseline) | `agent/coding_context.py`; `skip_context_files` | baseline |
| `.hermes.md` project file | presente no fork Hermes (baseline) | Mentioned in `agent_init` context injection | identity-core (rename?) |
| Subdirectory hints | presente no fork Hermes (baseline) | `agent/subdirectory_hints.py` | baseline |
| Context engine plugins | presente no fork Hermes (baseline) | `plugins/context_engine/`; toolset `context_engine` | baseline |
| Context references / breakdown | presente no fork Hermes (baseline) | `agent/context_references.py`, `context_breakdown.py` | baseline |
| Coding workspace detection | presente no fork Hermes (baseline) | `agent/coding_context.py` manifests + toolset coding | baseline |

---

## 11. Security / approvals

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Dangerous command approval | presente no fork Hermes (baseline) | `tools/approval.py` | baseline |
| Write approval | presente no fork Hermes (baseline) | `tools/write_approval.py`; `write_approval_commands` | baseline |
| Path security | presente no fork Hermes (baseline) | `tools/path_security.py` | baseline |
| URL safety / website policy | presente no fork Hermes (baseline) | `tools/url_safety.py`, `website_policy.py` | baseline |
| Tirith security | presente no fork Hermes (baseline) | `tools/tirith_security.py` | baseline |
| Threat patterns | presente no fork Hermes (baseline) | `tools/threat_patterns.py` | baseline |
| Security audit CLI | presente no fork Hermes (baseline) | `hermes_cli/security_audit.py`; `hermes security` | cli-entry |
| Network egress isolation doc | presente no fork Hermes (baseline) | `docs/security/network-egress-isolation.md` | baseline |
| ACP edit approval / permissions | presente no fork Hermes (baseline) | `acp_adapter/edit_approval.py`, `permissions.py` | baseline |
| Secrets CLI / 1Password | presente no fork Hermes (baseline) | `hermes_cli/secrets_cli.py`, `onepassword_secrets_cli.py` | baseline |
| Secret scope / sources | presente no fork Hermes (baseline) | `agent/secret_scope.py`, `secret_sources/` | baseline |
| Redaction | presente no fork Hermes (baseline) | `agent/redact.py` | baseline |
| Security-guidance plugin | presente no fork Hermes (baseline) | `plugins/security-guidance/` | baseline |
| Dashboard auth providers | presente no fork Hermes (baseline) | `plugins/dashboard_auth/*`; `hermes_cli/dashboard_auth/` | baseline |
| MCP security gates | presente no fork Hermes (baseline) | `hermes_cli/mcp_security.py` | baseline |
| Slash confirm | presente no fork Hermes (baseline) | `tools/slash_confirm.py` | baseline |

---

## 12. ACP (editor integration)

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| ACP adapter package | presente no fork Hermes (baseline) | `acp_adapter/` (`server.py`, `session.py`, `tools.py`) | baseline |
| ACP registry manifest | presente no fork Hermes (baseline) | `acp_registry/agent.json` | docs-brand / identity-core |
| `hermes acp` subcommand | presente no fork Hermes (baseline) | `hermes_cli/subcommands/acp.py` | cli-entry |
| Auth / provenance / events | presente no fork Hermes (baseline) | `acp_adapter/auth.py`, `provenance.py`, `events.py` | baseline |
| VS Code / Zed / JetBrains surface | presente no fork Hermes (baseline) | Docs + ACP protocol entry `__main__.py` | baseline |

---

## 13. TUI / CLI / Desktop / Web

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Classic CLI (`cli.py` / Rich + prompt_toolkit) | presente no fork Hermes (baseline) | `hermes` interactive | cli-entry |
| Central slash command registry | presente no fork Hermes (baseline) | `hermes_cli/commands.py` | cli-entry |
| Ink TUI (`ui-tui/`) | presente no fork Hermes (baseline) | `hermes --tui` / `HERMES_TUI=1` | cli-entry |
| TUI gateway (JSON-RPC) | presente no fork Hermes (baseline) | `tui_gateway/server.py` | baseline |
| Skin engine | presente no fork Hermes (baseline) | `hermes_cli/skin_engine.py`; `/skin` | persona-defaults |
| Banner / display | presente no fork Hermes (baseline) | `hermes_cli/banner.py`; `agent/display.py` | persona-defaults |
| Dashboard web UI | presente no fork Hermes (baseline) | `web/`; `hermes dashboard` | baseline |
| `hermes serve` headless backend | presente no fork Hermes (baseline) | Desktop spawn path in AGENTS.md | baseline |
| Electron desktop app | presente no fork Hermes (baseline) | `apps/desktop/` | docs-brand / install-windows |
| Shared gateway client package | presente no fork Hermes (baseline) | `apps/shared/` | baseline |
| PTY bridge (dashboard embed TUI) | presente no fork Hermes (baseline) | `hermes_cli/pty_bridge.py`; Windows `win_pty_bridge.py` | smoke-windows |
| Bootstrap installer (Tauri/etc.) | presente no fork Hermes (baseline) | `apps/bootstrap-installer/` | install-windows |
| i18n locales | presente no fork Hermes (baseline) | `locales/*.yaml` | baseline |
| Console engine | presente no fork Hermes (baseline) | `hermes_cli/console_engine.py` | baseline |

---

## 14. Install / doctor / update

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Install script Linux/macOS | presente no fork Hermes (baseline) | README curl install.sh (upstream URL) | install-windows (mirror EVA) |
| Install script Windows PowerShell | presente no fork Hermes (baseline) | README `install.ps1`; home `%LOCALAPPDATA%\hermes` | install-windows → `%LOCALAPPDATA%\eva` |
| `setup-hermes.sh` | presente no fork Hermes (baseline) | Root script | identity-core |
| `hermes setup` wizard | presente no fork Hermes (baseline) | `hermes_cli/setup.py` | cli-entry |
| `hermes doctor` | presente no fork Hermes (baseline) | `hermes_cli/doctor.py` | cli-entry / smoke-windows |
| `hermes update` | presente no fork Hermes (baseline) | subcommand `update` | cli-entry |
| `hermes uninstall` | presente no fork Hermes (baseline) | subcommand `uninstall` | cli-entry |
| `hermes version` / build info | presente no fork Hermes (baseline) | `build_info.py`; version subcommand | baseline |
| Homebrew formula | presente no fork Hermes (baseline) | `packaging/homebrew/` | baseline |
| Nix flake | presente no fork Hermes (baseline) | `flake.nix`; `nix/` | baseline |
| Docker / compose | presente no fork Hermes (baseline) | `Dockerfile`; `docker-compose.yml`; Windows compose | baseline |
| Postinstall | presente no fork Hermes (baseline) | subcommand `postinstall` | install-windows |
| Termux constraints | presente no fork Hermes (baseline) | `constraints-termux.txt`; README Termux | baseline |
| uv-managed Python env | presente no fork Hermes (baseline) | `uv.lock`; `managed_uv.py` | baseline |
| Claw migrate | presente no fork Hermes (baseline) | `hermes claw migrate` | baseline |

---

## 15. Terminal backends

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Local backend | presente no fork Hermes (baseline) | `tools/environments/local.py` | baseline |
| Docker backend | presente no fork Hermes (baseline) | `tools/environments/docker.py` | baseline |
| SSH backend | presente no fork Hermes (baseline) | `tools/environments/ssh.py` | baseline |
| Singularity backend | presente no fork Hermes (baseline) | `tools/environments/singularity.py` | baseline |
| Modal backend | presente no fork Hermes (baseline) | `tools/environments/modal.py`, `managed_modal.py` | baseline |
| Daytona backend | presente no fork Hermes (baseline) | `tools/environments/daytona.py` | baseline |
| File sync helpers | presente no fork Hermes (baseline) | `tools/environments/file_sync.py` | baseline |
| Env base ABC | presente no fork Hermes (baseline) | `tools/environments/base.py` | baseline |
| Config `terminal.cwd` | presente no fork Hermes (baseline) | config.yaml; gateway bridge | baseline |
| Background process + notify | presente no fork Hermes (baseline) | terminal tool + gateway watcher; `display.background_process_notifications` | baseline |
| Windows Git Bash / MinGit path | presente no fork Hermes (baseline) | README Windows install notes | install-windows / smoke-windows |

---

## 16. Browser

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Browser tool surface (navigate/snapshot/click/…) | presente no fork Hermes (baseline) | `tools/browser_tool.py`; core tools list | baseline |
| Browser CDP | presente no fork Hermes (baseline) | `tools/browser_cdp_tool.py` | baseline |
| Browser dialog | presente no fork Hermes (baseline) | `tools/browser_dialog_tool.py` | baseline |
| Browser supervisor | presente no fork Hermes (baseline) | `tools/browser_supervisor.py` | baseline |
| Camofox | presente no fork Hermes (baseline) | `tools/browser_camofox.py` | baseline |
| Browser providers (browser-use, browserbase, firecrawl) | presente no fork Hermes (baseline) | `plugins/browser/*` | baseline |
| `hermes` browser connect CLI | presente no fork Hermes (baseline) | `hermes_cli/browser_connect.py` | baseline |
| Browser registry (agent) | presente no fork Hermes (baseline) | `agent/browser_registry.py`, `browser_provider.py` | baseline |
| Datagen browser tasks examples | presente no fork Hermes (baseline) | `datagen-config-examples/example_browser_tasks.jsonl` | baseline |

---

## 17. Trajectories / research / datagen

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Trajectory save helpers | presente no fork Hermes (baseline) | `agent/trajectory.py` | baseline |
| Trajectory compressor | presente no fork Hermes (baseline) | `trajectory_compressor.py` | baseline |
| Batch trajectory generation | presente no fork Hermes (baseline) | `batch_runner.py`; README research-ready | baseline |
| Datagen config examples | presente no fork Hermes (baseline) | `datagen-config-examples/*` | baseline |
| Mini SWE runner | presente no fork Hermes (baseline) | `mini_swe_runner.py` | baseline |
| Trace upload | presente no fork Hermes (baseline) | `agent/trace_upload.py` | baseline |
| Observability plugins (Langfuse, NeMo) | presente no fork Hermes (baseline) | `plugins/observability/*` | baseline |

---

## 18. Profiles, config, plugins (transversal)

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| Profiles multi-instance | presente no fork Hermes (baseline) | `hermes_cli/profiles.py`; `get_hermes_home()` | identity-core |
| Default home POSIX `~/.hermes` | presente no fork Hermes (baseline) | `hermes_constants.get_hermes_home` | identity-core → EVA home |
| Default home Windows `%LOCALAPPDATA%\hermes` | presente no fork Hermes (baseline) | same; README Windows | identity-core → `%LOCALAPPDATA%\eva` |
| config.yaml + DEFAULT_CONFIG | presente no fork Hermes (baseline) | `hermes_cli/config.py` | baseline |
| .env secrets only policy | presente no fork Hermes (baseline) | OPTIONAL_ENV_VARS; AGENTS.md | baseline |
| General plugin manager | presente no fork Hermes (baseline) | `hermes_cli/plugins.py` | baseline |
| `hermes plugins` CLI | presente no fork Hermes (baseline) | subcommand plugins | cli-entry |
| Hooks system | presente no fork Hermes (baseline) | `hermes_cli/hooks.py`; gateway hooks | baseline |
| Backup / import / dump / debug | presente no fork Hermes (baseline) | subcommands | baseline |
| Status / logs / insights | presente no fork Hermes (baseline) | subcommands + `agent/insights.py` | baseline |
| Pets | presente no fork Hermes (baseline) | `agent/pet/`; `hermes_cli/pets.py` | baseline |
| Goals / journey / tips | presente no fork Hermes (baseline) | respective hermes_cli modules | baseline |
| Billing / subscription (Nous) | presente no fork Hermes (baseline) | `agent/billing_*`; `docs/billing-lifecycle.md` | baseline |
| Proxy server | presente no fork Hermes (baseline) | `hermes_cli/proxy/` | baseline |
| Website Docusaurus docs | presente no fork Hermes (baseline) | `website/` | docs-brand |

---

## 19. Rebrand EVA (produto — checklist de aceite)

Estas linhas são o **alvo de produto** do fork; o motor baseline acima permanece até cada frente fechar.

| Feature | Status no fork | Como validar | Owner/frente |
|---------|----------------|--------------|--------------|
| CLI binário/comando `eva` | presente no fork Hermes (baseline) | Ainda entry `hermes` / package hermes — rebrand pendente | cli-entry |
| Home Windows `%LOCALAPPDATA%\eva` | presente no fork Hermes (baseline) | Ainda `%LOCALAPPDATA%\hermes` no constants/README | identity-core / install-windows |
| Home POSIX `~/.eva` (se definido) | presente no fork Hermes (baseline) | Ainda `~/.hermes` | identity-core |
| Marca/copy EVA (README, banner, skins) | presente no fork Hermes (baseline) | README ainda Hermes Agent / Nous | docs-brand / persona-defaults |
| Env prefix `EVA_*` vs `HERMES_*` | presente no fork Hermes (baseline) | Vars ainda `HERMES_*` | identity-core |
| Manter LICENSE MIT Nous | presente no fork Hermes (baseline) | `LICENSE` presente | baseline (não remover) |
| NOTICE Nous Research | presente no fork Hermes (baseline) | NOTICE ausente no tree atual — adicionar se política EVA exigir, sem apagar crédito | docs-brand |
| Não depender de pacote Hermes externo | presente no fork Hermes (baseline) | monorepo = motor; sem `pip install hermes-agent` como runtime externo | baseline |

> Status “baseline” nas linhas de rebrand significa: **feature Hermes intacta; rename EVA ainda não aplicado neste worktree**. Não são gaps de capacidade.

---

## Critérios de aceite (produto)

1. **Nenhuma capability listada como gap** sem plano de restauração ou `N/A EVA` aprovado.
2. Smoke por categoria (owner da frente) passa em Windows nativo quando aplicável (`smoke-windows`).
3. Após rebrand: `eva doctor`, `eva tools`, gateway, TUI, cron, memory FTS5, delegate, MCP, browser, trajectories exercitáveis com home EVA.
4. LICENSE/atribuição Nous preservados.
5. Esta matriz atualizada quando um item mudar de status (PR que fecha frente atualiza a linha).

---

## Como atualizar

1. Prove com comando ou path de código.
2. Mude só a linha afetada (`Status`, `Como validar`, `Owner`).
3. Se for gap: descreva evidência (arquivo removido, teste falhando, commit).
4. Não marque gap por string “Hermes” sozinha — isso é rebrand, não perda de feature.

---

## Inventário rápido (fonte)

| Área | Onde olhar |
|------|------------|
| Core loop | `run_agent.py`, `agent/` |
| Tools | `tools/`, `toolsets.py`, `model_tools.py` |
| CLI | `hermes_cli/`, `cli.py` |
| Gateway | `gateway/`, `plugins/platforms/` |
| Cron | `cron/` |
| Memory | `hermes_state.py`, `plugins/memory/` |
| Providers | `plugins/model-providers/` |
| TUI/Desktop | `ui-tui/`, `tui_gateway/`, `apps/desktop/`, `web/` |
| ACP | `acp_adapter/`, `acp_registry/` |
| Skills | `skills/`, `optional-skills/` |
| Tests | `tests/` (~2k+ files), `scripts/run_tests.sh` |

---

*Documento gerado na frente maestro `parity-matrix` (docs-technical). Baseline = fork Hermes completo neste worktree; rebrand EVA em frentes paralelas.*
