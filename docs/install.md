# Install And Operations Guide

This page keeps the detailed install, verification, and troubleshooting notes for the Mercusys MA530 Linux Bluetooth driver fix.

## Status

- Tested on Ubuntu with Linux `6.14.x`.
- Builds an out-of-tree `btusb.ko` module.
- Adds MA530 `2c4e:0115` to the Realtek `btusb` device table.
- Loads Realtek firmware from `/lib/firmware/rtl_bt/rtl8761bu_fw.bin`.
- Includes helper scripts for pairing, reconnecting, autosuspend, and diagnostics.

This is not an official Mercusys or Realtek driver.

## What Is Included

- `patches/btusb-ma530.patch`: kernel `btusb` patch for MA530.
- `scripts/agent_install.sh`: no-input install/repair entry point.
- `scripts/bootstrap_source.sh`: prepares a minimal out-of-tree `btusb` source tree.
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

The agent installer can create an out-of-tree Bluetooth driver source directory automatically from local or installable Linux source. If you provide your own source directory, it should contain at least:

- `Makefile`
- `btusb.c`
- `ath3k.c`
- the Bluetooth helper headers used by `btusb.c`

By default the scripts create or reuse:

```bash
/usr/src/btusb-4.3
```

You can override it, but this is optional:

```bash
export BTUSB_SRC_DIR=/path/to/btusb-source
```

## Agent Install

For coding agents, start with [../AGENTS.md](../AGENTS.md). The default no-input command is:

```bash
./scripts/agent_install.sh
```

Optional pairing context:

```bash
TARGET_BT_MAC=AA:BB:CC:DD:EE:FF ./scripts/agent_install.sh
```

If the default flow fails because the host differs, the agent should extend the scripts and continue rather than asking for a source path immediately.

## Manual Install

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

## Safety Notes

- Do not publish local firmware blobs from `firmware/`.
- Do not publish Bluetooth MAC addresses from your own devices.
- Review logs before attaching them to an issue. `btmon`, `dmesg`, and `bluetoothctl` output may include device names and addresses.
