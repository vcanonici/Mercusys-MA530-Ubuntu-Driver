#!/usr/bin/env python3
"""Sanitize MA530 diagnostic logs before sharing."""

from __future__ import annotations

import argparse
import os
import re
import socket
from pathlib import Path

MAC_RE = re.compile(r"(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")
HOME_RE = re.compile(r"/home/[^/\s:]+")
SERIAL_RE = re.compile(r"(SerialNumber=)\S+")


def sanitize(text: str) -> str:
    hostname = socket.gethostname()
    user = os.environ.get("USER") or os.environ.get("LOGNAME") or ""

    text = MAC_RE.sub("XX:XX:XX:XX:XX:XX", text)
    text = HOME_RE.sub("/home/<user>", text)
    text = SERIAL_RE.sub(r"\1<redacted>", text)

    if hostname:
        text = re.sub(rf"\b{re.escape(hostname)}\b", "<hostname>", text)
    if user:
        text = re.sub(rf"\b{re.escape(user)}\b", "<user>", text)

    return text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", help="Log file to sanitize in place")
    args = parser.parse_args()

    path = Path(args.path)
    text = path.read_text(encoding="utf-8", errors="replace")
    path.write_text(sanitize(text), encoding="utf-8")
    print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
