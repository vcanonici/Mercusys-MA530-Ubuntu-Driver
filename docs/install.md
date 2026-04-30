# Install And Operations Guide

This guide covers installation, verification, rollback, and diagnostics for the Mercusys MA530 Linux `btusb` fix.

## 1. Prerequisites

Target hardware:

```text
Mercusys MA530 Bluetooth Nano USB Adapter
USB ID: 2c4e:0115
Realtek family: RTL8761BU / RTL8761BUV
```

Install dependencies on Ubuntu or Debian-based systems:

```bash
sudo apt-get update
sudo apt-get install -y build-essential linux-headers-$(uname -r) bluez usbutils ripgrep patch
```

For DKMS:

```bash
sudo apt-get install -y dkms
```

Firmware should come from the distribution:

```text
/lib/firmware/rtl_bt/rtl8761bu_fw.bin
/lib/firmware/rtl_bt/rtl8761bu_config.bin
```

If firmware is missing, install or repair your distribution firmware package explicitly:

```bash
sudo apt-get install -y linux-firmware
```

`scripts/bootstrap_source.sh` can install `linux-source` only when it cannot find a usable local Bluetooth source tree.

## 2. DKMS Installation

DKMS is recommended when available because it can rebuild the patched module after kernel updates:

```bash
MA530_USE_DKMS=1 ./scripts/agent_install.sh
```

Direct DKMS commands:

```bash
./scripts/dkms_install.sh
dkms status | rg ma530-btusb
./scripts/verify_driver.sh
```

Generated DKMS source is placed under:

```text
/usr/src/ma530-btusb-0.1.0/
```

## 3. Manual Installation

```bash
export KVER="$(uname -r)"
export BTUSB_SRC_DIR="${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}"

./scripts/bootstrap_source.sh "${BTUSB_SRC_DIR}"
./scripts/prepare_source.sh "${BTUSB_SRC_DIR}"
./scripts/build_driver.sh "${KVER}"
./scripts/install_driver.sh "${KVER}"
./scripts/load_driver.sh "${KVER}"
```

[patches/btusb-ma530-minimal.patch](../patches/btusb-ma530-minimal.patch) only adds the MA530 USB ID to the Realtek `btusb` table. [patches/btusb-ma530.patch](../patches/btusb-ma530.patch) is kept as a compatibility fallback for source trees that need the older broader patch.

## 4. Verification

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

Useful manual checks:

```bash
modinfo -n btusb
modinfo /lib/modules/$(uname -r)/updates/btusb.ko | rg -n 'srcversion|vermagic|version'
lsmod | rg -n '^btusb|^btrtl|^bluetooth'
sudo dmesg | rg -i 'MA530|RTL|btusb|rtl8761bu' | tail -n 120
bluetoothctl show
```

## 5. Optional Pairing

Do not pair before driver and controller verification pass.

```bash
./scripts/scan_devices.sh 20
bluetoothctl devices
./scripts/pair_device.sh <MAC>
bluetoothctl info <MAC>
```

Optional reconnect support:

```bash
sudo ./scripts/install_system_integration.sh <MAC>
./scripts/disable_autosuspend.sh
```

## 6. Rebuild After Kernel Update

With DKMS:

```bash
sudo dkms autoinstall
./scripts/verify_driver.sh
```

Manual rebuild:

```bash
export KVER="$(uname -r)"
./scripts/bootstrap_source.sh "${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}"
./scripts/prepare_source.sh "${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}"
./scripts/build_driver.sh "${KVER}"
./scripts/install_driver.sh "${KVER}"
./scripts/load_driver.sh "${KVER}"
./scripts/verify_driver.sh
```

## 7. Rollback

Manual module rollback:

```bash
./scripts/uninstall_driver.sh
modinfo -n btusb || true
```

DKMS rollback:

```bash
./scripts/dkms_remove.sh
sudo depmod -a
sudo modprobe -r btusb || true
sudo modprobe btusb || true
modinfo -n btusb || true
```

Rollback does not remove firmware, Bluetooth packages, Bluetooth configuration, or `/var/lib/bluetooth/`.

## 8. Secure Boot

The installer checks Secure Boot state when `mokutil` is present:

```bash
mokutil --sb-state
```

If Secure Boot is enabled, unsigned modules may fail to load. Diagnose with:

```bash
sudo dmesg | rg -i 'module verification|signature|key rejected|Required key not available'
```

This repository does not generate or enroll MOK keys automatically. See [secure-boot.md](secure-boot.md).

## 9. Diagnostics

```bash
./scripts/collect_diagnostics.sh
ls logs/
```

The diagnostics file is sanitized in place. It masks Bluetooth MAC addresses, `/home/<user>` paths, local hostnames, and serial numbers before you attach it to an issue.
