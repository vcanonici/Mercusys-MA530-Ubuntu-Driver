# Power Failure Recovery Runbook (MA530 + Bluetooth Keyboard)

## Scope
This document records what was done after a power failure where:
- the Bluetooth keyboard stopped connecting,
- the dongle appeared unstable,
- the custom btusb path looked reverted.

## Root Cause Found
1. Kernel changed to `6.17.0-14-generic`, so the custom `btusb` needed a rebuild for the new kernel.
2. Keyboard BLE MAC changed from old values (`...:4F`, `...:52`) to `<KEYBOARD_MAC>`.
3. Legacy auto-connect units were still pointing to stale MACs.

## Actions Executed
1. Verified dongle/controller state:
- `lsusb` showed `2c4e:0115` (MERCUSYS).
- `hciconfig -a` showed Realtek `LMP Subversion 0x8761`.

2. Rebuilt and reinstalled custom btusb for running kernel:
- `./scripts/build_driver.sh`
- `./scripts/install_driver.sh`
- `./scripts/load_driver.sh`

3. Validated custom module is active:
- `modinfo /lib/modules/$(uname -r)/updates/btusb.ko`
- `srcversion=76EBEFCEF830922FEEF6470`
- Kernel logs included:
  - `MA530: binding RTL8761BU via btusb`
  - `RTL: loading rtl_bt/rtl8761bu_fw.bin`
  - `RTL: fw version 0xdfc6d922`

4. Repaired keyboard pairing with current MAC:
- `bluetoothctl trust <KEYBOARD_MAC>`
- `bluetoothctl connect <KEYBOARD_MAC>`

5. Removed stale services and enabled keepalive on current MAC:
- disabled old `bt-auto-connect@...` and old keepalive instances
- enabled `bt-keepalive@<KEYBOARD_MAC>.service`

6. Confirmed final state:
- `Paired/Bonded/Trusted/Connected = yes`
- keepalive service `enabled` + `active`

## Current Known-Good Values
- Kernel: `6.17.0-14-generic`
- BlueZ (`bluetoothctl`): `5.72`
- Active btusb path: `/lib/modules/6.17.0-14-generic/updates/btusb.ko`
- Active btusb srcversion: `76EBEFCEF830922FEEF6470`
- Keyboard MAC: `<KEYBOARD_MAC>`
- Keyboard name: `<KEYBOARD_NAME>`

## If It Breaks Again (Quick Fix)
1. Driver integrity first:
- `uname -r`
- `modinfo -n btusb`
- `modinfo /lib/modules/$(uname -r)/updates/btusb.ko | rg srcversion`

2. Rebuild/reinstall for current kernel:
- `cd Mercusys-MA530-Ubuntu-Driver`
- `./scripts/build_driver.sh`
- `./scripts/install_driver.sh`
- `./scripts/load_driver.sh`

3. Discover current keyboard MAC (BLE MAC may rotate):
- put keyboard in pairing mode
- `./scripts/scan_devices.sh 20`
- `bluetoothctl devices | rg -i '<KEYBOARD_NAME>|keyboard'`

4. Re-bind keepalive to current MAC:
- `sudo systemctl disable --now bt-keepalive@OLD_MAC.service`
- `sudo systemctl enable --now bt-keepalive@NEW_MAC.service`

5. Verify:
- `bluetoothctl info NEW_MAC`
- `bluetoothctl devices Connected`
- `sudo systemctl status bt-keepalive@NEW_MAC.service --no-pager`

## Notes
- BLE keyboards can rotate random addresses; service instances tied to static old MACs will fail.
- Keepalive should target only one current MAC to avoid instability.
