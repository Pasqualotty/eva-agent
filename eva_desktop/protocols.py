"""Typing contracts for the Windows Desk shell ↔ EVA Agent core boundary.

Mirror of ``eva_desk.bridge.protocols`` (evagent) so the agent core can
depend on these shapes without importing Tk, pystray, or ``app_stable``.

All host callbacks may be invoked from **non-UI threads** (pynput / pystray
daemon threads). The host must marshal onto its main loop (asyncio queue,
Tk ``after``, etc.).
"""

from __future__ import annotations

from pathlib import Path
from typing import Callable, Literal, Protocol, runtime_checkable

# --- presentation -----------------------------------------------------------

PresentationMode = Literal["resident", "window"]

ShowPanelFn = Callable[[], None]
QuitFn = Callable[[], None]
MuteToggleFn = Callable[[], None]
ReconnectFn = Callable[[], None]
UserTextFn = Callable[[str], None]
SpeakFn = Callable[[str], None]
ErrorFn = Callable[[str], None]

# Event names from EVA-DESK-BRIDGE §6 (stable wire names).
ShellEventName = Literal[
    "tray.show",
    "tray.quit",
    "tray.mute_toggle",
    "tray.reconnect",
    "ptt.listening",
    "ptt.transcribing",
    "ptt.audio_ready",
    "ptt.error",
    "voice.speak_request",
    "voice.state",
]


@runtime_checkable
class DeskShellCallbacks(Protocol):
    """Host-facing hooks the Windows shell may invoke.

    Methods should be safe to call from non-UI threads; the host marshals.
    """

    def on_show_panel(self) -> None:
        """User requested the chat/panel (tray default action)."""
        ...

    def on_quit(self) -> None:
        """User requested full application exit."""
        ...

    def on_mute_toggle(self) -> None:
        """Toggle TTS auto-speak / mute (host owns the flag)."""
        ...

    def on_reconnect(self) -> None:
        """Reconnect agent session / brain transport."""
        ...

    def on_user_text(self, text: str) -> None:
        """Final STT (or equivalent) user utterance ready for the core."""
        ...

    def on_shell_error(self, message: str) -> None:
        """Recoverable shell error (PTT/mic/Voicebox) for toast/log."""
        ...


@runtime_checkable
class TraySurface(Protocol):
    """Minimal tray surface (Desk: ``TrayController``)."""

    @property
    def available(self) -> bool: ...

    def start(self) -> None: ...

    def stop(self) -> None: ...

    def notify(self, message: str) -> None: ...


@runtime_checkable
class PTTSurface(Protocol):
    """Minimal push-to-talk surface (Desk: ``PTTController``)."""

    def start(self) -> None: ...

    def stop(self) -> None: ...

    @property
    def is_listening(self) -> bool: ...


@runtime_checkable
class VoiceSurface(Protocol):
    """Minimal voice façade (Desk: ``VoiceService`` / Voicebox)."""

    def ensure_running(self, timeout_s: float = 30.0) -> bool: ...

    def warm_up(self, **kwargs: object) -> dict: ...

    def speak_text(
        self, text: str, *, on_start: Callable[[], None] | None = None
    ) -> None: ...

    def transcribe(self, path_or_bytes: str | Path | bytes) -> str: ...
