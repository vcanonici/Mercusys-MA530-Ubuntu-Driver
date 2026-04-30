#!/usr/bin/env python3
"""Parse Realtek Bluetooth firmware (EPATCH v1/v2)."""

from __future__ import annotations

import argparse
import binascii
import struct
import sys
from typing import Any, Dict, List, Optional

EPATCH_SIG = b"Realtech"
EPATCH_SIG_V2 = b"RTBTCore"
EXT_SIG = b"\x51\x04\xfd\x77"


def u16le(data: bytes, off: int) -> int:
    return struct.unpack_from("<H", data, off)[0]


def u32le(data: bytes, off: int) -> int:
    return struct.unpack_from("<I", data, off)[0]


def find_project_id_v1(data: bytes, header_len: int) -> Optional[int]:
    ext_pos = len(data) - len(EXT_SIG)
    if ext_pos < header_len + 3:
        return None

    # Walk backwards as the driver does.
    idx = ext_pos
    min_idx = header_len + 3

    while idx >= min_idx:
        idx -= 1
        if idx < 0:
            break
        opcode = data[idx]

        idx -= 1
        if idx < 0:
            break
        length = data[idx]

        idx -= 1
        if idx < 0:
            break
        value = data[idx]

        if opcode == 0xFF:
            break

        if length == 0:
            return None

        if opcode == 0x00 and length == 0x01:
            return value

        idx -= length

    return None


def parse_v1(data: bytes) -> Dict[str, Any]:
    if len(data) < 14:
        raise ValueError("File too small for EPATCH v1 header")

    fw_version = u32le(data, 8)
    num_patches = u16le(data, 12)
    header_len = 8 + 4 + 2

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
    project_id = find_project_id_v1(data, header_len)

    return {
        "format": "epatch-v1",
        "fw_version": fw_version,
        "num_patches": num_patches,
        "patches": patches,
        "extension_sig_ok": ext_ok,
        "project_id": project_id,
    }


def parse_v2(data: bytes) -> Dict[str, Any]:
    if len(data) < 20:
        raise ValueError("File too small for EPATCH v2 header")

    fw_version_raw = data[8:16]
    num_sections = u32le(data, 16)
    idx = 20
    sections: List[Dict[str, Any]] = []

    for i in range(num_sections):
        if idx + 8 > len(data):
            break
        opcode = u32le(data, idx)
        length = u32le(data, idx + 4)
        idx += 8
        if idx + length > len(data):
            break
        sections.append(
            {
                "index": i,
                "opcode": opcode,
                "length": length,
                "data_off": idx,
            }
        )
        idx += length

    ext_ok = data.endswith(EXT_SIG)

    return {
        "format": "epatch-v2",
        "fw_version_raw": binascii.hexlify(fw_version_raw).decode("ascii"),
        "num_sections": num_sections,
        "sections": sections,
        "extension_sig_ok": ext_ok,
    }


def parse_fw(data: bytes) -> Dict[str, Any]:
    sig = data[:8]

    if sig == EPATCH_SIG:
        return parse_v1(data)
    if sig == EPATCH_SIG_V2:
        return parse_v2(data)

    raise ValueError(f"Unknown signature: {sig!r}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", help="Path to firmware .bin")
    args = parser.parse_args()

    with open(args.path, "rb") as f:
        data = f.read()

    try:
        info = parse_fw(data)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    print(f"file: {args.path}")
    print(f"size: {len(data)}")
    print(f"format: {info['format']}")

    if info["format"] == "epatch-v1":
        print(f"fw_version: 0x{info['fw_version']:08x}")
        print(f"num_patches: {info['num_patches']}")
        print(f"extension_sig_ok: {info['extension_sig_ok']}")
        print(f"project_id: {info['project_id']}")
        print("patches:")
        for patch in info["patches"]:
            print(
                "  - index={index} chip_id=0x{chip_id:04x} "
                "len=0x{patch_len:04x} off=0x{patch_off:08x}".format(**patch)
            )
    else:
        print(f"fw_version_raw: {info['fw_version_raw']}")
        print(f"num_sections: {info['num_sections']}")
        print(f"extension_sig_ok: {info['extension_sig_ok']}")
        print("sections:")
        for sec in info["sections"]:
            print(
                "  - index={index} opcode=0x{opcode:08x} "
                "len=0x{length:08x} off=0x{data_off:08x}".format(**sec)
            )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
