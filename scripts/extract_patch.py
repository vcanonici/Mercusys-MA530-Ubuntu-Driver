#!/usr/bin/env python3
"""Extract a Realtek EPATCH v1 patch by index or chip ID."""

from __future__ import annotations

import argparse
import struct
import sys
from typing import List, Dict, Any

EPATCH_SIG = b"Realtech"
EXT_SIG = b"\x51\x04\xfd\x77"


def u16le(data: bytes, off: int) -> int:
    return struct.unpack_from("<H", data, off)[0]


def u32le(data: bytes, off: int) -> int:
    return struct.unpack_from("<I", data, off)[0]


def parse_epatch_v1(data: bytes) -> Dict[str, Any]:
    if not data.startswith(EPATCH_SIG):
        raise ValueError("Not EPATCH v1 (missing Realtech signature)")
    if len(data) < 14:
        raise ValueError("File too small for EPATCH v1 header")

    fw_version = u32le(data, 8)
    num_patches = u16le(data, 12)
    header_len = 14

    meta_len = (2 * num_patches) + (2 * num_patches) + (4 * num_patches)
    if len(data) < header_len + meta_len:
        raise ValueError("File too small for patch metadata")

    chip_base = header_len
    length_base = chip_base + (2 * num_patches)
    offset_base = length_base + (2 * num_patches)

    patches: List[Dict[str, Any]] = []
    for i in range(num_patches):
        chip_id = u16le(data, chip_base + (2 * i))
        patch_len = u16le(data, length_base + (2 * i))
        patch_off = u32le(data, offset_base + (4 * i))
        patches.append(
            {
                "index": i,
                "chip_id": chip_id,
                "patch_len": patch_len,
                "patch_off": patch_off,
            }
        )

    ext_ok = data.endswith(EXT_SIG)

    return {
        "fw_version": fw_version,
        "num_patches": num_patches,
        "patches": patches,
        "extension_sig_ok": ext_ok,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("fw", help="Firmware .bin (EPATCH v1)")
    parser.add_argument("--out", required=True, help="Output patch file")
    parser.add_argument("--index", type=int, help="Patch index to extract")
    parser.add_argument("--chip-id", help="Chip ID (hex, e.g. 0x0002)")
    parser.add_argument(
        "--raw",
        action="store_true",
        help="Write raw patch bytes without appending fw_version",
    )
    args = parser.parse_args()

    with open(args.fw, "rb") as f:
        data = f.read()

    info = parse_epatch_v1(data)

    if args.index is None and args.chip_id is None:
        print("Available patches:")
        for p in info["patches"]:
            print(
                "  - index={index} chip_id=0x{chip_id:04x} "
                "len=0x{patch_len:04x} off=0x{patch_off:08x}".format(**p)
            )
        print("error: choose --index or --chip-id", file=sys.stderr)
        return 1

    target = None
    if args.index is not None:
        if args.index < 0 or args.index >= info["num_patches"]:
            print("error: invalid index", file=sys.stderr)
            return 1
        target = info["patches"][args.index]
    else:
        chip_id = int(args.chip_id, 16)
        for p in info["patches"]:
            if p["chip_id"] == chip_id:
                target = p
                break
        if target is None:
            print("error: chip ID not found", file=sys.stderr)
            return 1

    off = target["patch_off"]
    length = target["patch_len"]
    if off + length > len(data):
        print("error: patch out of bounds", file=sys.stderr)
        return 1

    patch = data[off : off + length]
    if not args.raw:
        if length < 4:
            print("error: patch too small", file=sys.stderr)
            return 1
        patch = patch[:-4] + struct.pack("<I", info["fw_version"])

    with open(args.out, "wb") as f:
        f.write(patch)

    print("wrote", args.out)
    print("index:", target["index"], "chip_id:", f"0x{target['chip_id']:04x}")
    print("raw_length:", length, "final_length:", len(patch))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
