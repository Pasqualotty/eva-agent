"""``eva desk`` / ``hermes desk`` — Windows Desk shell wire stub.

Prints integration guide for tray/PTT/Voicebox (Eva Desk bridge). Distinct
from ``eva desktop`` / ``eva gui`` (Electron chat app).
"""

from __future__ import annotations

from typing import Callable


def build_desk_parser(subparsers, *, cmd_desk: Callable) -> None:
    """Attach the ``desk`` subcommand to ``subparsers``."""
    desk_parser = subparsers.add_parser(
        "desk",
        help="Windows Desk shell wire (tray/PTT/Voicebox integration stub)",
        description=(
            "Show how to integrate the EVA Desk Windows shell (tray, PTT, "
            "Voicebox Eva Humana) with this agent core. Does not start a live "
            "tray — see docs/DESKTOP-SHELL.md and eva_desktop package."
        ),
    )
    desk_parser.add_argument(
        "desk_action",
        nargs="?",
        default="guide",
        choices=["guide", "status", "events", "voicebox", "help"],
        help="guide (default), status, events, or voicebox defaults",
    )
    desk_parser.add_argument(
        "--json",
        action="store_true",
        help="Machine-readable output for status/events/voicebox",
    )
    desk_parser.add_argument(
        "--resident",
        action="store_true",
        help="Force presentation mode resident (status)",
    )
    desk_parser.add_argument(
        "--window",
        action="store_true",
        help="Force presentation mode window (status)",
    )
    desk_parser.set_defaults(func=cmd_desk)
