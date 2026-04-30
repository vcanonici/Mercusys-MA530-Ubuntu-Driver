# AGENTS.md (Public)

This repository contains tooling and notes for maintaining a Mercusys MA530 Bluetooth adapter on Ubuntu Linux.

## Mission
Keep Bluetooth keyboard connectivity stable by prioritizing driver integrity, then pairing/connectivity maintenance.

## Public Safe Guidelines
- Do not store passwords, tokens, or private credentials.
- Do not publish personally identifying machine details.
- Keep troubleshooting reproducible with command-based checks.

## First Response Checklist (Always)
Before any pairing actions, verify driver integrity:
1. `uname -r`
2. `modinfo -n btusb`
3. `modinfo /lib/modules/$(uname -r)/updates/btusb.ko | rg -n 'srcversion|vermagic|version'`
4. `lsmod | rg -n '^btusb|^btrtl|^bluetooth'`

If custom `btusb` is missing for current kernel, rebuild and reinstall:
1. `./scripts/build_driver.sh`
2. `./scripts/install_driver.sh`
3. `./scripts/load_driver.sh`

## Keyboard Recovery Flow
1. Confirm adapter/controller is healthy:
- `lsusb | rg -i '2c4e:0115|mercusys'`
- `hciconfig -a`
- `bluetoothctl show`

2. Discover current keyboard address (BLE addresses may rotate):
- put keyboard in pairing mode
- `./scripts/scan_devices.sh 20`
- `bluetoothctl devices`

3. Pair/connect/trust:
- `./scripts/pair_device.sh <MAC>`
- `bluetoothctl info <MAC>`

4. Keepalive (optional, one device only):
- `sudo systemctl enable --now bt-keepalive@<MAC>.service`
- disable stale services bound to old MACs.

## Repository Map
- `scripts/`:
  - Driver lifecycle: `build_driver.sh`, `install_driver.sh`, `load_driver.sh`, `driver_status.sh`
  - Bluetooth ops: `scan_devices.sh`, `pair_device.sh`, `keyboard_info.sh`, `keep_bt_connected.sh`
  - System integration: `install_system_integration.sh`, `disable_autosuspend.sh`
  - Firmware/RE helpers: `parse_rtl_fw.py`, `extract_patch.py`, `decode_config.py`, `capture_btmon.sh`
- `patches/`: `btusb-ma530.patch`
- `notes/`: runbooks and operational notes
- `driver/`: build outputs by kernel version
- `firmware/`: local blobs for testing (proprietary; do not redistribute blindly)

## Useful Versions (Example)
- Kernel: `6.17.0-14-generic`
- BlueZ: `5.72`
- btusb custom srcversion example: `76EBEFCEF830922FEEF6470`

Update this section when environment changes.

## Troubleshooting Priority
1. Driver integrity
2. Adapter power/state
3. Pairing database and current BLE MAC
4. Autoconnect/keepalive service consistency
