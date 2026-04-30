#!/usr/bin/env python3
"""Decode Realtek vendor config blob (rtl_vendor_config)."""

from __future__ import annotations

import argparse
import binascii
import struct
import sys

RTL_CONFIG_MAGIC = 0x8723AB55


def u16le(data: bytes, off: int) -> int:
    return struct.unpack_from("<H", data, off)[0]


def u32le(data: bytes, off: int) -> int:
    return struct.unpack_from("<I", data, off)[0]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", help="Config .bin")
    args = parser.parse_args()

    with open(args.path, "rb") as f:
        data = f.read()

    if len(data) < 6:
        print("error: too small", file=sys.stderr)
        return 1

    sig = u32le(data, 0)
    total_len = u16le(data, 4)

    print(f"file: {args.path}")
    print(f"size: {len(data)}")
    print(f"signature: 0x{sig:08x}")
    print(f"total_len: {total_len}")

    if sig != RTL_CONFIG_MAGIC:
        print("warning: signature does not match RTL_CONFIG_MAGIC")
        print("raw_hex:", binascii.hexlify(data).decode("ascii"))
        return 0

    pos = 6
    end = 6 + total_len
    idx = 0

    while pos + 3 <= len(data) and pos < end:
        offset = u16le(data, pos)
        length = data[pos + 2]
        pos += 3
        if pos + length > len(data):
            print("error: entry out of bounds", file=sys.stderr)
            return 1
        blob = data[pos : pos + length]
        pos += length

        print(
            "entry[{idx}] offset=0x{offset:04x} len={length} data={hex}".format(
                idx=idx, offset=offset, length=length, hex=binascii.hexlify(blob).decode("ascii")
            )
        )
        idx += 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
