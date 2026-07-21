"""EVA Desktop shell wire — adapter stub for Windows Desk (tray/PTT/Voicebox).

This package lives in **eva-agent** (Hermes fork). It defines the I/O contract
aligned with the Desk bridge export (``eva_desk.bridge`` / ``docs/EVA-DESK-BRIDGE.md``
in the ``evagent`` repo) **without** importing or copying the monolithic
``app_stable`` UI.

Phase B of the Desk wire plan: stable protocols + stub host adapter here;
real tray/PTT/Voicebox still live in the Desk package until wired (C1/C2/C3).

Public entry points::

    from eva_desktop import (
        DeskShellAdapter,
        DeskShellCallbacks,
        SHELL_EVENTS,
        VOICEBOX_DEFAULTS,
        create_desk_adapter,
        format_integration_guide,
        resolve_presentation_mode,
    )
"""

from __future__ import annotations

from eva_desktop.adapter import DeskShellAdapter, NullHost, create_desk_adapter
from eva_desktop.contract import (
    APP_DISPLAY_NAME,
    AUTOSTART_APP_ID,
    DESK_BRIDGE_DOC_HINT,
    MODE_RESIDENT,
    MODE_WINDOW,
    SHELL_EVENTS,
    TRAY_TITLE,
    VOICEBOX_DEFAULTS,
    format_integration_guide,
    resolve_presentation_mode,
)
from eva_desktop.protocols import (
    DeskShellCallbacks,
    PresentationMode,
    ShellEventName,
)

__all__ = [
    "APP_DISPLAY_NAME",
    "AUTOSTART_APP_ID",
    "DESK_BRIDGE_DOC_HINT",
    "DeskShellAdapter",
    "DeskShellCallbacks",
    "MODE_RESIDENT",
    "MODE_WINDOW",
    "NullHost",
    "PresentationMode",
    "SHELL_EVENTS",
    "ShellEventName",
    "TRAY_TITLE",
    "VOICEBOX_DEFAULTS",
    "create_desk_adapter",
    "format_integration_guide",
    "resolve_presentation_mode",
]

__version__ = "0.1.0"
