# Mercusys MA530 Linux Bluetooth Driver Fix

Linux notes, scripts, and a `btusb` patch for the **Mercusys MA530 Bluetooth Nano USB Adapter** on Ubuntu and other Ubuntu-based distributions.

This project targets the MA530 USB ID **`2c4e:0115`**, which presents as a Realtek **RTL8761BU / RTL8761BUV** Bluetooth controller. It is useful when the adapter is detected but Bluetooth scanning, pairing, or reconnecting devices is unreliable on Linux.

## Keywords

Mercusys MA530 Linux driver, MA530 Ubuntu Bluetooth, `2c4e:0115`, Realtek RTL8761BU Linux, RTL8761BUV, `btusb`, `btrtl`, Bluetooth keyboard Linux, Ubuntu Bluetooth dongle fix.

## Status

- Tested on Ubuntu with Linux `6.14.x`.
- Builds an out-of-tree `btusb.ko` module.
- Adds MA530 `2c4e:0115` to the Realtek `btusb` device table.
- Loads Realtek firmware from `/lib/firmware/rtl_bt/rtl8761bu_fw.bin`.
- Includes helper scripts for pairing, reconnecting, autosuspend, and diagnostics.

This is not an official Mercusys or Realtek driver.

## What Is Included

- `patches/btusb-ma530.patch`: kernel `btusb` patch for MA530.
- `scripts/build_driver.sh`: builds `btusb.ko` from a prepared source tree.
- `scripts/install_driver.sh`: installs the module into `/lib/modules/<kernel>/updates/`.
- `scripts/load_driver.sh`: reloads `btusb` so the patched module is used.
- Bluetooth recovery helpers for scanning, pairing, trust/connect, keepalive, and autosuspend.
- Notes documenting the reverse-engineering and recovery workflow.

## What Is Not Included

- Realtek firmware blobs. They are proprietary and should come from your system package under `/lib/firmware/rtl_bt/`.
- A full Linux kernel source tree. This repo ships the MA530 patch and helper scripts, not a copy of upstream `btusb.c`.
- DKMS packaging. The current workflow is explicit rebuild/install after kernel updates.

## Requirements

Install the usual kernel build and Bluetooth tools:

```bash
sudo apt update
sudo apt install build-essential linux-headers-$(uname -r) linux-firmware bluez usbutils ripgrep patch
```

You also need an out-of-tree Bluetooth driver source directory containing at least:

- `Makefile`
- `btusb.c`
- `ath3k.c`
- the Bluetooth helper headers used by `btusb.c`

By default the scripts expect this directory at:

```bash
/usr/src/btusb-4.3
```

You can override it:

```bash
export BTUSB_SRC_DIR=/path/to/btusb-source
```

## For Coding Agents

This repository is agent-operable. Start with [AGENTS.md](AGENTS.md), which contains:

- the MA530 hardware context (`2c4e:0115`, Realtek RTL8761BU/RTL8761BUV),
- the single-shot install/repair command flow,
- required inputs such as `BTUSB_SRC_DIR`,
- optional pairing via `TARGET_BT_MAC`,
- success criteria and stop conditions.

Autonomous agents should not begin with pairing. They should verify and repair driver integrity first.

Minimal agent invocation context:

```bash
export BTUSB_SRC_DIR=/usr/src/btusb-4.3
# optional:
export TARGET_BT_MAC=AA:BB:CC:DD:EE:FF
```

Then follow the **Single-Shot Install Flow** in `AGENTS.md`.

## Quick Start

1. Confirm the adapter is present:

```bash
lsusb | rg -i '2c4e:0115|mercusys'
```

2. Prepare the `btusb` source tree by applying the MA530 patch:

```bash
export BTUSB_SRC_DIR=/usr/src/btusb-4.3
./scripts/prepare_source.sh
```

3. Build, install, and load the patched driver:

```bash
./scripts/build_driver.sh
./scripts/install_driver.sh
./scripts/load_driver.sh
```

4. Verify that Linux is using the patched module:

```bash
modinfo -n btusb
modinfo /lib/modules/$(uname -r)/updates/btusb.ko | rg -n 'srcversion|vermagic|version'
sudo dmesg | rg -i 'MA530|RTL|btusb'
```

Expected signs:

- `modinfo -n btusb` points to `/lib/modules/<kernel>/updates/btusb.ko`
- kernel logs include `MA530: binding RTL8761BU via btusb`
- kernel logs include Realtek firmware loading, such as `rtl8761bu_fw.bin`

## Pair A Keyboard Or Mouse

Put the device in pairing mode, then:

```bash
./scripts/scan_devices.sh 20
bluetoothctl devices
./scripts/pair_device.sh <MAC>
bluetoothctl info <MAC>
```

For reconnect stability:

```bash
sudo ./scripts/install_system_integration.sh <MAC>
./scripts/disable_autosuspend.sh
```

If you cannot use `sudo` yet, install a user-session autoconnect service:

```bash
./scripts/install_user_autoconnect.sh <MAC>
```

## After A Kernel Update

Rebuild the module for the new kernel:

```bash
uname -r
./scripts/build_driver.sh
./scripts/install_driver.sh
./scripts/load_driver.sh
```

Then verify again:

```bash
modinfo -n btusb
sudo dmesg | rg -i 'MA530|RTL|btusb'
```

## Troubleshooting Checklist

Driver integrity first:

```bash
uname -r
modinfo -n btusb
modinfo /lib/modules/$(uname -r)/updates/btusb.ko | rg -n 'srcversion|vermagic|version'
lsmod | rg -n '^btusb|^btrtl|^bluetooth'
```

Adapter/controller state:

```bash
lsusb | rg -i '2c4e:0115|mercusys'
hciconfig -a
bluetoothctl show
```

Pairing state:

```bash
bluetoothctl devices
bluetoothctl info <MAC>
```

BLE keyboards may rotate addresses. If reconnect services point to old MACs, disable stale service instances and bind keepalive/autoconnect to the current MAC only.

## GitHub Topics

Recommended repository topics:

```text
mercusys ma530 linux ubuntu bluetooth rtl8761bu rtl8761buv btusb btrtl realtek 2c4e-0115 bluetooth-keyboard
```

Suggested GitHub description:

```text
Linux btusb patch and Ubuntu helper scripts for the Mercusys MA530 Bluetooth USB adapter (2c4e:0115, Realtek RTL8761BU/RTL8761BUV).
```

## Safety Notes

- Do not publish local firmware blobs from `firmware/`.
- Do not publish Bluetooth MAC addresses from your own devices.
- Review logs before attaching them to an issue. `btmon`, `dmesg`, and `bluetoothctl` output may include device names and addresses.

## License

Scripts and documentation are MIT licensed.

The kernel patch applies to Linux Bluetooth driver code, which is GPL-2.0-or-later upstream. Treat patched kernel module builds as GPL-derived kernel artifacts.
