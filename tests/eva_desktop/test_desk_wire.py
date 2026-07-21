"""Minimal tests for eva_desktop Desk shell wire stub."""

from __future__ import annotations

import json
import os
from unittest.mock import patch

import pytest

from eva_desktop import (
    MODE_RESIDENT,
    MODE_WINDOW,
    SHELL_EVENTS,
    VOICEBOX_DEFAULTS,
    DeskShellAdapter,
    create_desk_adapter,
    format_integration_guide,
    resolve_presentation_mode,
)
from eva_desktop.cli import cmd_desk
from eva_desktop.contract import show_window_on_start
from eva_desktop.protocols import DeskShellCallbacks


class RecordingHost:
    def __init__(self) -> None:
        self.events: list[tuple[str, object]] = []

    def on_show_panel(self) -> None:
        self.events.append(("show", None))

    def on_quit(self) -> None:
        self.events.append(("quit", None))

    def on_mute_toggle(self) -> None:
        self.events.append(("mute", None))

    def on_reconnect(self) -> None:
        self.events.append(("reconnect", None))

    def on_user_text(self, text: str) -> None:
        self.events.append(("text", text))

    def on_shell_error(self, message: str) -> None:
        self.events.append(("error", message))


def test_recording_host_satisfies_protocol() -> None:
    assert isinstance(RecordingHost(), DeskShellCallbacks)


def test_voicebox_defaults_eva_humana() -> None:
    assert VOICEBOX_DEFAULTS["profile"] == "Eva Humana"
    assert VOICEBOX_DEFAULTS["engine"] == "qwen"
    assert VOICEBOX_DEFAULTS["model_size"] == "0.6B"
    assert VOICEBOX_DEFAULTS["language"] == "pt"
    assert VOICEBOX_DEFAULTS["voicebox_url"] == "http://127.0.0.1:17493"
    assert VOICEBOX_DEFAULTS["open_system_player"] is False
    assert "ctrl" in str(VOICEBOX_DEFAULTS["ptt_hotkey"]).lower()


def test_shell_events_catalog_has_tray_ptt_voice() -> None:
    required = {
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
    }
    assert required <= set(SHELL_EVENTS.keys())


def test_resolve_presentation_mode_cli_and_env() -> None:
    assert resolve_presentation_mode(argv=["--window"]) == MODE_WINDOW
    assert resolve_presentation_mode(argv=["--resident"]) == MODE_RESIDENT
    with patch.dict(os.environ, {"EVA_AGENT_MODE": "window"}):
        assert resolve_presentation_mode(argv=[]) == MODE_WINDOW
    with patch.dict(os.environ, {"EVA_AGENT_MODE": ""}):
        assert resolve_presentation_mode(argv=[], cfg=None) == MODE_RESIDENT
    assert (
        resolve_presentation_mode(
            cfg={"agent": {"resident_default": False}}, argv=[]
        )
        == MODE_WINDOW
    )


def test_show_window_on_start() -> None:
    assert show_window_on_start(mode="window") is True
    assert show_window_on_start(mode="resident") is False


def test_adapter_lifecycle_and_callbacks() -> None:
    host = RecordingHost()
    adapter = create_desk_adapter(host=host, mode="resident")
    assert adapter.is_stub is True
    assert adapter.started is False

    adapter.start()
    assert adapter.started is True
    st = adapter.status()
    assert st["backend"] == "stub"
    assert st["live_shell"] is False
    assert st["mode"] == "resident"

    adapter.speak("olá eva")
    assert adapter.status()["last_speak"] == "olá eva"
    adapter.notify("toast")
    assert adapter.status()["last_notify"] == "toast"

    adapter.emit_user_text("oi")
    adapter.emit_tray_show()
    adapter.emit_mute_toggle()
    adapter.emit_reconnect()
    adapter.emit_tray_quit()
    adapter.emit_shell_error("mic fail")

    kinds = [e[0] for e in host.events]
    assert kinds == ["text", "show", "mute", "reconnect", "quit", "error"]
    assert host.events[0] == ("text", "oi")

    adapter.stop()
    assert adapter.started is False


def test_start_is_idempotent() -> None:
    a = DeskShellAdapter()
    a.start()
    a.start()
    assert a.started is True
    a.stop()
    a.stop()
    assert a.started is False


def test_format_integration_guide_mentions_surfaces() -> None:
    text = format_integration_guide(platform="win32")
    assert "tray" in text.lower()
    assert "PTT" in text or "ptt" in text.lower()
    assert "Voicebox" in text or "voicebox" in text.lower()
    assert "Eva Humana" in text
    assert "eva desk" in text.lower()
    assert "app_stable" in text  # warns not to copy monólito


def test_cmd_desk_guide_exit_zero(capsys: pytest.CaptureFixture[str]) -> None:
    import argparse

    rc = cmd_desk(argparse.Namespace(desk_action="guide", json=False))
    assert rc == 0
    out = capsys.readouterr().out
    assert "integration" in out.lower() or "integra" in out.lower() or "tray" in out.lower()


def test_cmd_desk_status_json(capsys: pytest.CaptureFixture[str]) -> None:
    import argparse

    rc = cmd_desk(
        argparse.Namespace(
            desk_action="status",
            json=True,
            window=False,
            resident=True,
        )
    )
    assert rc == 0
    data = json.loads(capsys.readouterr().out)
    assert data["backend"] == "stub"
    assert data["is_stub"] is True
    assert data["mode"] == "resident"


def test_cmd_desk_events_json(capsys: pytest.CaptureFixture[str]) -> None:
    import argparse

    rc = cmd_desk(argparse.Namespace(desk_action="events", json=True))
    assert rc == 0
    data = json.loads(capsys.readouterr().out)
    assert "tray.show" in data
