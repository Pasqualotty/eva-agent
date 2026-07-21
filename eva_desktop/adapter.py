"""Stub Desk shell adapter for the EVA Agent core.

Does **not** start tray, PTT, or Voicebox. Records lifecycle intent so hosts
and tests can exercise the contract before the real ``eva_desk.bridge``
package is installed. Safe on all platforms (including non-Windows).
"""

from __future__ import annotations

import logging
import sys
import threading
from typing import Any, Mapping

from eva_desktop.contract import (
    MODE_RESIDENT,
    resolve_presentation_mode,
    show_window_on_start,
)
from eva_desktop.protocols import DeskShellCallbacks, PresentationMode

log = logging.getLogger("eva_desktop.adapter")


class NullHost:
    """No-op host used when only constructing the adapter for tests/CLI."""

    def on_show_panel(self) -> None:
        return None

    def on_quit(self) -> None:
        return None

    def on_mute_toggle(self) -> None:
        return None

    def on_reconnect(self) -> None:
        return None

    def on_user_text(self, text: str) -> None:
        return None

    def on_shell_error(self, message: str) -> None:
        return None


class DeskShellAdapter:
    """In-core stub mirroring ``eva_desk.bridge.facade.DeskShell`` lifecycle.

    Parameters
    ----------
    host:
        Object implementing :class:`DeskShellCallbacks` (duck-typed).
    cfg:
        Optional mapping (config fragment); used only for mode resolution.
    mode:
        ``resident`` or ``window``; resolved from cfg/CLI/env if omitted.
    enable_tray / enable_ptt / enable_voice:
        Intent flags only — stub never opens native surfaces.
    """

    def __init__(
        self,
        host: DeskShellCallbacks | None = None,
        cfg: Mapping[str, Any] | None = None,
        *,
        mode: PresentationMode | str | None = None,
        enable_tray: bool = True,
        enable_ptt: bool = True,
        enable_voice: bool = True,
        warm_up_voice: bool = True,
    ) -> None:
        self.host: DeskShellCallbacks = (
            host if host is not None else NullHost()  # type: ignore[assignment]
        )
        self.cfg = cfg
        self.mode: str = str(mode or resolve_presentation_mode(cfg))
        self.enable_tray = bool(enable_tray)
        self.enable_ptt = bool(enable_ptt)
        self.enable_voice = bool(enable_voice)
        self.warm_up_voice = bool(warm_up_voice)

        self._started = False
        self._lock = threading.Lock()
        self._last_speak: str | None = None
        self._last_notify: str | None = None
        self._status: dict[str, Any] = {
            "backend": "stub",
            "live_shell": False,
            "note": "Install eva_desk.bridge for real tray/PTT/Voicebox",
        }

    # --- public API (aligned with DeskShell façade) ------------------------

    @property
    def started(self) -> bool:
        return self._started

    @property
    def is_stub(self) -> bool:
        return True

    @property
    def platform_supported(self) -> bool:
        """True when a live Windows shell would be eligible (win32)."""
        return sys.platform == "win32"

    def show_panel_on_start(self) -> bool:
        return show_window_on_start(self.cfg, mode=self.mode)  # type: ignore[arg-type]

    def start(self) -> None:
        """Mark shell started; does not open tray/mic/Voicebox."""
        with self._lock:
            if self._started:
                return
            self._started = True

        self._status.update(
            {
                "backend": "stub",
                "live_shell": False,
                "mode": self.mode,
                "tray_enabled": self.enable_tray,
                "ptt_enabled": self.enable_ptt,
                "voice_enabled": self.enable_voice,
                "warm_up_voice": self.warm_up_voice,
                "platform": sys.platform,
                "platform_supported": self.platform_supported,
            }
        )
        log.info(
            "DeskShellAdapter (stub) started mode=%s tray=%s ptt=%s voice=%s platform=%s",
            self.mode,
            self.enable_tray,
            self.enable_ptt,
            self.enable_voice,
            sys.platform,
        )

    def stop(self) -> None:
        """Idempotent stop."""
        with self._lock:
            self._started = False
        log.info("DeskShellAdapter (stub) stopped")

    def speak(self, text: str, *, on_start: Any = None) -> None:
        """Record TTS request; no Voicebox call."""
        self._last_speak = text
        if on_start is not None:
            try:
                on_start()
            except Exception:
                log.debug("speak on_start failed", exc_info=True)
        log.debug("stub speak skipped (no voice): %r", (text or "")[:80])

    def notify(self, message: str) -> None:
        """Record tray toast intent."""
        self._last_notify = message
        log.debug("stub notify: %s", message)

    def status(self) -> dict[str, Any]:
        """Snapshot for ``eva desk status`` and tests."""
        snap = dict(self._status)
        snap["started"] = self._started
        snap["mode"] = self.mode
        snap["show_window_on_start"] = self.show_panel_on_start()
        snap["last_speak"] = self._last_speak
        snap["last_notify"] = self._last_notify
        snap["is_stub"] = True
        return snap

    # --- test helpers: simulate shell → host events -------------------------

    def emit_user_text(self, text: str) -> None:
        """Simulate ``ptt.audio_ready`` → STT → host.on_user_text."""
        try:
            self.host.on_user_text(text)
        except Exception as exc:
            log.warning("host.on_user_text failed: %s", exc)
            try:
                self.host.on_shell_error(str(exc) or "on_user_text failed")
            except Exception:
                pass

    def emit_tray_show(self) -> None:
        self.host.on_show_panel()

    def emit_tray_quit(self) -> None:
        self.host.on_quit()

    def emit_mute_toggle(self) -> None:
        self.host.on_mute_toggle()

    def emit_reconnect(self) -> None:
        self.host.on_reconnect()

    def emit_shell_error(self, message: str) -> None:
        self.host.on_shell_error(message)


def create_desk_adapter(
    host: DeskShellCallbacks | None = None,
    cfg: Mapping[str, Any] | None = None,
    **kwargs: Any,
) -> DeskShellAdapter:
    """Factory matching Desk ``create_desk_shell`` naming for future swap."""
    return DeskShellAdapter(host=host, cfg=cfg, **kwargs)


# Default presentation when nothing configured
_DEFAULT_MODE = MODE_RESIDENT
