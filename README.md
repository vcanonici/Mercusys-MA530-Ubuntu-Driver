# Mercusys MA530 Linux Bluetooth Driver

Community Linux support for the **Mercusys MA530 Bluetooth Nano USB Adapter**.

Some Linux systems see the adapter on USB but do not bind it through the correct Realtek Bluetooth path. This repository provides a small `btusb` fix for the MA530 USB ID, **`2c4e:0115`**, so the adapter is handled as a Realtek **RTL8761BU / RTL8761BUV** controller through `btusb` + `btrtl`.

This is not an official Mercusys, Realtek, or Linux kernel project.

## Vendor Support Status

Mercusys sells the MA530 with official Windows support but does not list Linux as supported for this adapter. This repository exists to provide a community-maintained Linux driver workflow for hardware that otherwise works.

## Supported Hardware

```text
Product: Mercusys MA530 Bluetooth Nano USB Adapter
USB ID: 2c4e:0115
Chip family: Realtek RTL8761BU / RTL8761BUV
Linux driver path: btusb + btrtl
Firmware path: /lib/firmware/rtl_bt/
Expected firmware: rtl8761bu_fw.bin, optionally rtl8761bu_config.bin
```

Firmware blobs are not included. Install them from your Linux distribution, usually through `linux-firmware`.

## What This Repository Provides

- Minimal `btusb` patch: [patches/btusb-ma530-minimal.patch](patches/btusb-ma530-minimal.patch)
- Compatibility fallback patch: [patches/btusb-ma530.patch](patches/btusb-ma530.patch)
- Source bootstrap and idempotent patch preparation
- Manual build/install/load flow for `/lib/modules/<kernel>/updates/`
- Optional DKMS workflow for rebuilds after kernel updates
- Verification, rollback, Secure Boot notes, and sanitized diagnostics
- Pairing/autoconnect helpers that run only after driver/controller verification in the main installer

## Quick Install

Recommended DKMS path:

```bash
MA530_USE_DKMS=1 ./scripts/agent_install.sh
```

Manual module path:

```bash
MA530_USE_DKMS=0 ./scripts/agent_install.sh
```

The default entrypoint remains:

```bash
./scripts/agent_install.sh
```

## Verify

```bash
./scripts/verify_driver.sh
echo $?
```

Return codes:

```text
0 = driver active and coherent
1 = module missing or kernel mismatch
2 = MA530 hardware absent
3 = module present, but Bluetooth controller absent
```

## Rollback

```bash
./scripts/uninstall_driver.sh
modinfo -n btusb || true
```

Rollback removes only modules installed under `/lib/modules/<kernel>/updates/`. It does not remove firmware, packages, Bluetooth configuration, or pairing databases.

## Secure Boot

Secure Boot may block unsigned local kernel modules. The installer detects Secure Boot with `mokutil` when available and prints a warning, but it does not create or enroll MOK keys automatically. See [docs/secure-boot.md](docs/secure-boot.md).

## Diagnostics

```bash
./scripts/collect_diagnostics.sh
```

The diagnostics file is written under `logs/` and sanitized by [scripts/sanitize_logs.py](scripts/sanitize_logs.py) to mask Bluetooth MAC addresses, `/home/<user>` paths, local hostnames, and serial numbers.

Do not publish unsanitized logs, firmware blobs, `.ko` files, build outputs, Bluetooth MAC addresses, hostnames, serial numbers, tokens, private keys, or credentials.

## Documentation

For the full workflow, see [docs/install.md](docs/install.md). Coding agents should also read [AGENTS.md](AGENTS.md).

## License

Scripts and documentation are MIT licensed.

The patch applies to Linux Bluetooth driver code, which is GPL-2.0-or-later upstream. Treat patched kernel module builds as GPL-derived kernel artifacts.
