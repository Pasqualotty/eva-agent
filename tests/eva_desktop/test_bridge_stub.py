"""Unit tests for eva_desktop Desk shell wire stub (no tray/Voicebox I/O)."""

from __future__ import annotations

import os
from unittest.mock import patch

from eva_desktop import (
    SHELL_EVENTS,
    VOICEBOX_DEFAULTS,
    DeskShellAdapter,
    DeskShellCallbacks,
    create_desk_adapter,
    format_integration_guide,
    resolve_presentation_mode,
)
from eva_desktop.cli import cmd_desk
from eva_desktop.contract import show_window_on_start


class _RecordingHost:
    def __init__(self) -> None:
        self.calls: list[tuple[str, object]] = []

    def on_show_panel(self) -> None:
        self.calls.append(("show", None))

    def on_quit(self) -> None:
        self.calls.append(("quit", None))

    def on_mute_toggle(self) -> None:
        self.calls.append(("mute", None))

    def on_reconnect(self) -> None:
        self.calls.append(("reconnect", None))

    def on_user_text(self, text: str) -> None:
        self.calls.append(("user_text", text))

    def on_shell_error(self, message: str) -> None:
        self.calls.append(("error", message))


def test_resolve_presentation_mode_priority() -> None:
    assert resolve_presentation_mode(argv=["--window"]) == "window"
    assert resolve_presentation_mode(argv=["--resident"]) == "resident"
    with patch.dict(os.environ, {"EVA_AGENT_MODE": "window"}, clear=False):
        assert resolve_presentation_mode(argv=[]) == "window"
    assert resolve_presentation_mode(cfg={"agent": {"mode": "window"}}, argv=[]) == (
        "window"
    )
    with patch.dict(os.environ, {}, clear=True):
        # Clear EVA_AGENT_MODE if present
        os.environ.pop("EVA_AGENT_MODE", None)
        assert resolve_presentation_mode(cfg=None, argv=[]) == "resident"


def test_show_window_on_start() -> None:
    assert show_window_on_start(mode="window") is True
    assert show_window_on_start(mode="resident") is False


def test_shell_events_vocabulary() -> None:
    assert "tray.show" in SHELL_EVENTS
    assert "ptt.audio_ready" in SHELL_EVENTS
    assert "voice.speak_request" in SHELL_EVENTS
    assert len(SHELL_EVENTS) >= 8


def test_voicebox_defaults_frozen() -> None:
    assert VOICEBOX_DEFAULTS["profile"] == "Eva Humana"
    assert VOICEBOX_DEFAULTS["engine"] == "qwen"
    assert VOICEBOX_DEFAULTS["model_size"] == "0.6B"
    assert VOICEBOX_DEFAULTS["open_system_player"] is False
    assert "17493" in str(VOICEBOX_DEFAULTS["voicebox_url"])


def test_adapter_lifecycle_and_callbacks() -> None:
    host = _RecordingHost()
    adapter = create_desk_adapter(host=host, mode="resident", warm_up_voice=True)
    assert isinstance(adapter, DeskShellAdapter)
    assert adapter.is_stub is True
    assert adapter.started is False

    adapter.start()
    assert adapter.started is True
    st = adapter.status()
    assert st["backend"] == "stub"
    assert st["live_shell"] is False
    assert st["is_stub"] is True

    adapter.speak("olá")
    assert adapter.status()["last_speak"] == "olá"

    adapter.emit_user_text("oi core")
    adapter.emit_tray_show()
    adapter.emit_mute_toggle()
    adapter.emit_reconnect()
    adapter.emit_shell_error("mic fail")
    adapter.emit_tray_quit()

    adapter.stop()
    assert adapter.started is False

    kinds = [c[0] for c in host.calls]
    assert kinds == [
        "user_text",
        "show",
        "mute",
        "reconnect",
        "error",
        "quit",
    ]
    assert host.calls[0] == ("user_text", "oi core")


def test_recording_host_satisfies_protocol() -> None:
    host = _RecordingHost()
    assert isinstance(host, DeskShellCallbacks)


def test_integration_guide_mentions_key_surfaces() -> None:
    guide = format_integration_guide(platform="win32")
    assert "tray" in guide.lower()
    assert "PTT" in guide or "ptt" in guide.lower()
    assert "Voicebox" in guide or "voicebox" in guide.lower() or "Eva Humana" in guide
    assert "app_stable" in guide
    assert "create_desk_adapter" in guide or "DeskShellCallbacks" in guide


def test_cli_guide_status_events_voicebox(capsys) -> None:
    import argparse

    assert cmd_desk(argparse.Namespace(desk_action="guide")) == 0
    out = capsys.readouterr().out
    assert "integration" in out.lower() or "Desk" in out

    assert (
        cmd_desk(
            argparse.Namespace(
                desk_action="status",
                json=False,
                window=False,
                resident=False,
            )
        )
        == 0
    )
    out = capsys.readouterr().out
    assert "stub" in out.lower()

    assert cmd_desk(argparse.Namespace(desk_action="events", json=False)) == 0
    out = capsys.readouterr().out
    assert "tray.show" in out

    assert cmd_desk(argparse.Namespace(desk_action="voicebox", json=False)) == 0
    out = capsys.readouterr().out
    assert "Eva Humana" in out
