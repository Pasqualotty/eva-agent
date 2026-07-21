"""CLI handlers for ``eva desk`` (Windows Desk shell wire stub)."""

from __future__ import annotations

import argparse
import json
import sys
from typing import Any

from eva_desktop.adapter import create_desk_adapter
from eva_desktop.contract import (
    SHELL_EVENTS,
    VOICEBOX_DEFAULTS,
    WIRE_OPTIONS,
    format_integration_guide,
    resolve_presentation_mode,
)


def cmd_desk(args: argparse.Namespace) -> int:
    """Entry for ``eva desk`` / ``hermes desk``."""
    action = getattr(args, "desk_action", None) or "guide"

    if action in (None, "guide", "help"):
        print(format_integration_guide())
        return 0

    if action == "status":
        return _cmd_status(args)

    if action == "events":
        return _cmd_events(json_mode=bool(getattr(args, "json", False)))

    if action == "voicebox":
        return _cmd_voicebox(json_mode=bool(getattr(args, "json", False)))

    print(f"Unknown desk action: {action}", file=sys.stderr)
    print("Try: eva desk | eva desk status | eva desk events | eva desk voicebox", file=sys.stderr)
    return 2


def _cmd_status(args: argparse.Namespace) -> int:
    mode = resolve_presentation_mode()
    if getattr(args, "window", False):
        mode = "window"
    if getattr(args, "resident", False):
        mode = "resident"

    adapter = create_desk_adapter(mode=mode)
    adapter.start()
    st = adapter.status()
    adapter.stop()

    if getattr(args, "json", False):
        print(json.dumps(st, indent=2, ensure_ascii=False))
        return 0

    print("EVA Desk shell adapter — status (stub)")
    print("-" * 40)
    for key in (
        "backend",
        "live_shell",
        "started",
        "mode",
        "platform",
        "platform_supported",
        "tray_enabled",
        "ptt_enabled",
        "voice_enabled",
        "show_window_on_start",
        "note",
    ):
        if key in st:
            print(f"  {key}: {st[key]}")
    print()
    print("Wire options:")
    for k, v in WIRE_OPTIONS.items():
        print(f"  {k}: {v}")
    print()
    print("Full guide:  eva desk")
    print("Docs:        docs/DESKTOP-SHELL.md")
    return 0


def _cmd_events(*, json_mode: bool) -> int:
    if json_mode:
        print(json.dumps(dict(SHELL_EVENTS), indent=2, ensure_ascii=False))
        return 0
    print("Shell events (EVA-DESK-BRIDGE §6) — shell → core")
    print("-" * 56)
    for name, desc in SHELL_EVENTS.items():
        print(f"  {name:22}  {desc}")
    return 0


def _cmd_voicebox(*, json_mode: bool) -> int:
    payload: dict[str, Any] = dict(VOICEBOX_DEFAULTS)
    if json_mode:
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return 0
    print("Voicebox defaults (Eva Humana) — do not renegotiate without ADR")
    print("-" * 56)
    for key, val in payload.items():
        print(f"  {key}: {val!r}")
    print()
    print("Live health: install Voicebox + eva_desk.voice; stub does not probe :17493")
    return 0
