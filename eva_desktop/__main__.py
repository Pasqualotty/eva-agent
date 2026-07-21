"""``python -m eva_desktop`` — print integration guide."""

from __future__ import annotations

import sys

from eva_desktop.contract import format_integration_guide


def main() -> int:
    print(format_integration_guide())
    return 0


if __name__ == "__main__":
    sys.exit(main())
