"""Stable Desk shell contract constants and integration guide text.

Aligned with ``docs/EVA-DESK-BRIDGE.md`` (evagent) §4–§6. Do not redefine
Voicebox Eva Humana policy here — import/bridge to Desk when wiring live.
"""

from __future__ import annotations

import os
import sys
from typing import Any, Mapping

from eva_desktop.protocols import PresentationMode, ShellEventName

# Product identity (matches Desk agent_mode defaults; rebrand target)
APP_DISPLAY_NAME = "EVA Agent"
TRAY_TITLE = "EVA Agent"
AUTOSTART_APP_ID = "EVAAgent"

MODE_RESIDENT: PresentationMode = "resident"
MODE_WINDOW: PresentationMode = "window"

# Where the full Desk bridge lives today (separate repo / package).
DESK_BRIDGE_DOC_HINT = (
    "evagent docs/EVA-DESK-BRIDGE.md · package eva_desk.bridge "
    "(TrayController, PTTController, VoiceService)"
)

# Voicebox / Eva Humana policy defaults (EVA-DESK-BRIDGE §4.3) — do not
# renegotiate without ADR. Agent core does not need these deps headless.
VOICEBOX_DEFAULTS: Mapping[str, Any] = {
    "profile": "Eva Humana",
    "engine": "qwen",
    "model_size": "0.6B",
    "language": "pt",
    "voicebox_url": "http://127.0.0.1:17493",
    "open_system_player": False,
    "ptt_hotkey": "ctrl+shift+space",
    "client_id": "eva-desk",
}

# Shell → core event catalog (EVA-DESK-BRIDGE §6)
SHELL_EVENTS: Mapping[ShellEventName, str] = {
    "tray.show": "menu / double-click — host shows panel",
    "tray.quit": "Sair — host clean shutdown (stop PTT/voice/tray)",
    "tray.mute_toggle": "Mutar — host flips voice.auto_speak / mute TTS",
    "tray.reconnect": "Reconectar — host restarts session/core",
    "ptt.listening": "PTT hold complete — UI Ouvindo",
    "ptt.transcribing": "PTT release — UI Transcrevendo…",
    "ptt.audio_ready": "WAV ready (Path) — VoiceService.transcribe → user message",
    "ptt.error": "mic/hotkey failure (str PT-BR) — toast / system line",
    "voice.speak_request": "core asks TTS (text) — VoiceService.speak_text",
    "voice.state": "health/warm dict — optional telemetry",
}

# Optional Windows deps for a full shell (not required by this stub package)
SHELL_OPTIONAL_DEPS: tuple[str, ...] = (
    "pystray",
    "Pillow",
    "pynput",
    "sounddevice",
)

# Wire options from EVA-DESK-BRIDGE §8 Fase C
WIRE_OPTIONS: Mapping[str, str] = {
    "C1": "in-process — import eva_desk.bridge on win32 (lowest PTT/TTS latency)",
    "C2": "side-car — Desk process shell only; IPC JSON-lines / named pipe",
    "C3": "hybrid — tray+PTT in-process; rich Tk panel lazy side-car",
}


def resolve_presentation_mode(
    cfg: Mapping[str, Any] | None = None,
    argv: list[str] | None = None,
) -> PresentationMode:
    """Resolve resident|window (CLI → env → config → default resident).

    Priority matches Desk ``resolve_agent_mode``:
    CLI ``--resident``/``--window`` → env ``EVA_AGENT_MODE`` →
    ``config.agent.resident_default`` → default ``resident``.
    """
    args = argv if argv is not None else sys.argv[1:]
    if "--window" in args:
        return "window"
    if "--resident" in args:
        return "resident"

    env = (os.environ.get("EVA_AGENT_MODE") or "").strip().lower()
    if env in ("resident", "window"):
        return env  # type: ignore[return-value]

    if cfg is not None:
        agent = cfg.get("agent") if isinstance(cfg, Mapping) else None
        if isinstance(agent, Mapping):
            if agent.get("resident_default") is False:
                return "window"
            mode = agent.get("mode")
            if mode in ("resident", "window"):
                return mode  # type: ignore[return-value]
        top = cfg.get("mode") if isinstance(cfg, Mapping) else None
        if top in ("resident", "window"):
            return top  # type: ignore[return-value]

    return MODE_RESIDENT


def show_window_on_start(
    cfg: Mapping[str, Any] | None = None,
    *,
    mode: PresentationMode | str | None = None,
) -> bool:
    """Whether the panel should be visible at start (window mode → True)."""
    resolved = mode or resolve_presentation_mode(cfg)
    return resolved == MODE_WINDOW


def format_integration_guide(*, platform: str | None = None) -> str:
    """Human-readable guide printed by ``eva desk`` (no live tray/PTT)."""
    plat = platform if platform is not None else sys.platform
    lines = [
        "EVA Desktop shell wire — integration guide (stub)",
        "=" * 56,
        "",
        f"Platform: {plat}",
        f"Display name: {APP_DISPLAY_NAME}",
        f"Tray title: {TRAY_TITLE}",
        f"Home (agent): %LOCALAPPDATA%\\eva  (Windows) / ~/.hermes or profile-aware get_hermes_home()",
        f"Desk bridge (source of truth): {DESK_BRIDGE_DOC_HINT}",
        "",
        "Architecture (shell ≠ brain)",
        "  Desk shell: tray, PTT, TTS/STT Voicebox (Eva Humana), HUD, autostart",
        "  Agent core: this repo — sessions, tools, gateway, prompt loop",
        "  Do NOT copy monólito app_stable into eva-agent.",
        "",
        "Contract — host implements DeskShellCallbacks:",
        "  on_show_panel, on_quit, on_mute_toggle, on_reconnect,",
        "  on_user_text(text), on_shell_error(message)",
        "  Callbacks may fire off the UI thread — marshal to main loop.",
        "",
        "Events shell → core (stable names):",
    ]
    for name, desc in SHELL_EVENTS.items():
        lines.append(f"  {name:22}  {desc}")

    lines.extend(
        [
            "",
            "Voicebox defaults (Eva Humana — do not renegotiate without ADR):",
        ]
    )
    for key, val in VOICEBOX_DEFAULTS.items():
        lines.append(f"  {key}: {val!r}")

    lines.extend(
        [
            "",
            "Wire options (Fase C):",
        ]
    )
    for key, desc in WIRE_OPTIONS.items():
        lines.append(f"  {key}: {desc}")
    lines.append("  Recommendation: C1 for tray+PTT+voice; lazy-import Desk package.")

    lines.extend(
        [
            "",
            "How to integrate (next steps)",
            "  1. pip install / path-install the Desk package that exports eva_desk.bridge",
            "  2. On win32 only: from eva_desk.bridge import create_desk_shell, DeskShellCallbacks",
            "  3. Implement callbacks that call AIAgent / session prompt (no Tk in core)",
            "  4. create_desk_shell(host=...).start()  # tray + PTT + voice.warm_up bg",
            "  5. On turn:end: shell.speak(reply) when auto_speak; never open system Media Player",
            "  6. Config voice/agent keys: migrate toward %LOCALAPPDATA%\\eva (legacy AppData\\EvaDesk)",
            "",
            "Optional deps (shell only — not required for headless/Linux core):",
            "  " + ", ".join(SHELL_OPTIONAL_DEPS),
            "  + local Voicebox.exe listening on :17493",
            "",
            "Stub adapter in this repo:",
            "  from eva_desktop import create_desk_adapter, format_integration_guide",
            "  adapter = create_desk_adapter(host=MyHost())",
            "  adapter.start()  # records intent; does NOT open tray/mic",
            "  See docs/DESKTOP-SHELL.md",
            "",
            "CLI:",
            "  eva desk              # this guide",
            "  eva desk status       # adapter/stub status + platform gates",
            "  eva desk events       # dump event catalog",
            "  eva desktop / eva gui # Electron chat app (different surface)",
            "",
        ]
    )
    return "\n".join(lines)
