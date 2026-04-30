# Mercusys MA530 Linux Bluetooth Driver

Community Linux support for the **Mercusys MA530 Bluetooth Nano USB Adapter**.

The MA530 is a small USB Bluetooth adapter sold for everyday things like keyboards, mice, headphones, and controllers. On Linux, this adapter may appear on USB but fail to behave like a reliable Bluetooth controller because its USB ID is not handled correctly by the stock driver path on some systems.

This repository fixes that by patching Linux `btusb` so the MA530 USB ID, **`2c4e:0115`**, is bound through the Realtek **RTL8761BU / RTL8761BUV** Bluetooth path.

## Why This Exists

Because Linux users should not have to throw away working hardware just because a vendor did not ship a driver.

If companies will not maintain Linux support for the products they sell, the community will. This repo is a practical example: understand the device, patch the driver path, document the recovery process, and share the work so the next person does not have to start from zero.

## What This Software Does

- Adds Mercusys MA530 `2c4e:0115` handling to Linux `btusb`.
- Builds an out-of-tree `btusb.ko` module for your current kernel.
- Installs the module into `/lib/modules/<kernel>/updates/`.
- Reloads Bluetooth so Linux uses the patched driver.
- Helps verify Realtek firmware loading.
- Includes helpers for pairing, reconnecting, autosuspend, diagnostics, and agent-driven install/repair.

This is not an official Mercusys, Realtek, or Linux kernel project. It is a community driver fix and operational toolkit.

## Who This Is For

Use this if you have a Mercusys MA530 Bluetooth adapter on Ubuntu or an Ubuntu-based Linux distribution and you see symptoms like:

- the adapter appears in `lsusb`, but Bluetooth is unreliable;
- Bluetooth scanning or pairing fails;
- a keyboard or mouse pairs once and then stops reconnecting;
- kernel logs mention Realtek Bluetooth firmware, but the controller is unstable;
- you want a reproducible way to rebuild the fix after kernel updates.

The target adapter is:

```text
USB ID: 2c4e:0115
Chip family: Realtek RTL8761BU / RTL8761BUV
Linux driver path: btusb + btrtl
```

## Quick Install

Clone the repository, plug in the adapter, then run:

```bash
./scripts/agent_install.sh
```

That script tries to install dependencies, prepare the driver source, apply the patch, build the module, install it, reload `btusb`, and print verification output.

For a manual install path, see [docs/install.md](docs/install.md).

## For Coding Agents

This repo is intentionally agent-operable. If you ask a coding agent to "implement the patch", it should start from [AGENTS.md](AGENTS.md) and use:

```bash
./scripts/agent_install.sh
```

The agent is allowed to improve the local automation if the host environment differs. The goal is a working MA530 driver install, not blind adherence to one exact script path.

## After Kernel Updates

Kernel updates require rebuilding the module:

```bash
./scripts/build_driver.sh
./scripts/install_driver.sh
./scripts/load_driver.sh
```

Then confirm:

```bash
modinfo -n btusb
sudo dmesg | rg -i 'MA530|RTL|btusb'
```

## What Is In The Repo

- [patches/btusb-ma530.patch](patches/btusb-ma530.patch): the MA530 `btusb` patch.
- [scripts/](scripts/): install, build, load, pairing, recovery, and diagnostics helpers.
- [AGENTS.md](AGENTS.md): instructions for autonomous coding agents.
- [docs/install.md](docs/install.md): detailed install and troubleshooting guide.
- [docs/repository.md](docs/repository.md): repo metadata, topics, and search keywords.
- [notes/](notes/): development notes and operational runbooks.

## What Is Not Included

This repo does not include proprietary Realtek firmware blobs or generated kernel modules. Firmware should come from your Linux distribution under `/lib/firmware/rtl_bt/`.

Build outputs, logs, firmware, and local captures are intentionally ignored.

## Safety

Before sharing logs, remove Bluetooth MAC addresses, hostnames, usernames, and personal device names. See [SECURITY.md](SECURITY.md).

## License

Scripts and documentation are MIT licensed.

The patch applies to Linux Bluetooth driver code, which is GPL-2.0-or-later upstream. Treat patched kernel module builds as GPL-derived kernel artifacts.
