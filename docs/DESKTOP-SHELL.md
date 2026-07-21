# EVA Desktop Shell — wire com Eva Desk (Windows)

**Status:** stub / contrato (Fase B)  
**Package neste repo:** `eva_desktop/`  
**CLI:** `eva desk` (alias de compatibilidade: `hermes desk`)  
**Contrato canônico (Desk export):** `evagent` → `docs/EVA-DESK-BRIDGE.md` + package `eva_desk.bridge`  
**Não confundir com:** `eva desktop` / `eva gui` (app Electron em `apps/desktop/`)

---

## 1. Objetivo

Permitir que o **agent core** (`Pasqualotty/eva-agent`, fork MIT Hermes) embuta ou chame a **shell Windows** do Eva Desk (tray, PTT, TTS/STT Voicebox “Eva Humana”) **sem** copiar o monólito `app_stable.py`.

| Camada | Papel | Onde |
|--------|--------|------|
| **Desk shell** | Tray, PTT, Voicebox, HUD, autostart | Package `eva_desk` (repo evagent) |
| **Agent core** | Sessões, tools, gateway, prompt loop | Este repo |
| **Wire stub** | Protocols + adapter + CLI de integração | `eva_desktop/` (este PR) |

---

## 2. Princípios

1. **Shell ≠ cérebro** — tray/PTT/voz não decidem tools.
2. **Callbacks injetados** — host implementa `DeskShellCallbacks`; shell não importa ACP/brains.
3. **Marshal para a thread da UI** — callbacks de pynput/pystray em daemon threads.
4. **Voicebox é processo local** — `http://127.0.0.1:17493`, perfil **Eva Humana**, engine Qwen **0.6B**, sem Media Player do SO.
5. **Offline-safe** — warm_up/health não derrubam o agent se Voicebox estiver off.
6. **Sem monólito na API** — importar `eva_desk.bridge` (ou este stub), nunca `app_stable`.

---

## 3. Package `eva_desktop`

```
eva_desktop/
  __init__.py      # exports públicos
  protocols.py     # DeskShellCallbacks, Tray/PTT/Voice surfaces, event names
  contract.py      # VOICEBOX_DEFAULTS, SHELL_EVENTS, format_integration_guide
  adapter.py       # DeskShellAdapter stub (não abre tray/mic)
  cli.py           # handlers de `eva desk`
  __main__.py      # python -m eva_desktop
```

### Host mínimo

```python
from eva_desktop import (
    DeskShellCallbacks,
    create_desk_adapter,
    format_integration_guide,
    resolve_presentation_mode,
)

class MyHost:
    def on_show_panel(self) -> None: ...
    def on_quit(self) -> None: ...
    def on_mute_toggle(self) -> None: ...
    def on_reconnect(self) -> None: ...
    def on_user_text(self, text: str) -> None:
        # → agent core prompt
        ...
    def on_shell_error(self, message: str) -> None: ...

mode = resolve_presentation_mode()  # resident | window
adapter = create_desk_adapter(host=MyHost(), mode=mode)
adapter.start()   # stub: só registra intent
# ...
adapter.speak("Olá")  # stub: não chama Voicebox
adapter.stop()
```

Quando o package Desk estiver instalado, o host troca para:

```python
from eva_desk.bridge import create_desk_shell, DeskShellCallbacks
shell = create_desk_shell(host=MyHost(), mode=mode)
shell.start()  # tray + PTT + voice.warm_up real
```

A superfície de callbacks é a **mesma** (espelho de `eva_desk.bridge.protocols`).

---

## 4. Eventos shell → core

| Evento | Host |
|--------|------|
| `tray.show` | `on_show_panel` |
| `tray.quit` | `on_quit` |
| `tray.mute_toggle` | `on_mute_toggle` |
| `tray.reconnect` | `on_reconnect` |
| `ptt.listening` / `ptt.transcribing` | UI status |
| `ptt.audio_ready` | STT → `on_user_text` |
| `ptt.error` | `on_shell_error` |
| `voice.speak_request` | `shell.speak` / `VoiceService.speak_text` |
| `voice.state` | telemetria opcional |

Listar no terminal: `eva desk events`.

---

## 5. Voicebox (Eva Humana)

Defaults (não renegociar sem ADR):

| Chave | Valor |
|-------|--------|
| profile | `Eva Humana` |
| engine | `qwen` |
| model_size | `0.6B` |
| language | `pt` |
| voicebox_url | `http://127.0.0.1:17493` |
| open_system_player | `False` |
| ptt_hotkey | `ctrl+shift+space` |

`eva desk voicebox` imprime a tabela. O **stub não faz health check** em `:17493`.

---

## 6. CLI

```bash
eva desk              # guia de integração (tray / PTT / Voicebox)
eva desk status       # status do adapter stub + platform gate
eva desk events       # catálogo de eventos
eva desk voicebox     # defaults Eva Humana
eva desk status --json
python -m eva_desktop
```

**Distinto de:**

```bash
eva desktop   # app Electron (apps/desktop)
eva gui       # alias legado de desktop
```

---

## 7. Wire futuro (Fase C)

| Opção | Descrição |
|-------|-----------|
| **C1 in-process** | Core importa `eva_desk.bridge` em `win32` (recomendado PTT/TTS) |
| **C2 side-car** | Processo Desk só shell; IPC JSON-lines / named pipe |
| **C3 hybrid** | tray+PTT in-process; painel Tk lazy |

Home agent: `%LOCALAPPDATA%\eva\`  
Config legada Desk: `%APPDATA%\EvaDesk\` até migrar chaves `voice` / `agent` / `tray`.

---

## 8. O que **não** entra nesta frente

- Implementar tray/PTT/Voicebox dentro do loop Hermes
- Copiar `app_stable` / widgets / brains do Desk
- Gateway Telegram (outro workstream)
- App Electron (`apps/desktop`) — já existe e não é a shell Windows de voz

---

## 9. Testes

```bash
# Preferir o wrapper do repo quando o venv estiver ok:
scripts/run_tests.sh tests/eva_desktop/ -q

# Ou pytest direto no módulo isolado:
python -m pytest tests/eva_desktop/ -q
```

---

## 10. Referências

- `evagent/docs/EVA-DESK-BRIDGE.md` — contrato completo e mapa de fontes Desk  
- `eva_desk.bridge` — Protocols + façade + `BRIDGE_SOURCE_FILES`  
- `docs/EVA-PARITY.md` — matriz de paridade produto  
- `docs/install-windows.md` — home `%LOCALAPPDATA%\eva`  
- NOTICE / LICENSE — crédito Nous Research (fork MIT Hermes)
