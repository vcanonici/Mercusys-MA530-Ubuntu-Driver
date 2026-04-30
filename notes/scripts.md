# MA530 RE - Scripts

## Collection
- `scripts/collect_device_info.sh`
  - Gathers USB/BT logs, module info, and kernel logs into `logs/<timestamp>/`.

## Capture
- `scripts/capture_btmon.sh`
  - Captures HCI traffic to a `.btsnoop` file with a matching log.
  - Use while replugging the dongle or running `scripts/rebind_btusb.sh`.

- `scripts/rebind_btusb.sh`
  - Unbinds and rebinds btusb for all bound interfaces.

## Firmware
- `scripts/copy_firmware.sh [base]`
  - Copies firmware/config from `/lib/firmware/rtl_bt` and decompresses `.zst`.
  - Default base is `rtl8761bu`.

- `scripts/parse_rtl_fw.py <fw.bin>`
  - Parses EPATCH v1/v2 firmware and prints patch/section metadata.

- `scripts/extract_patch.py <fw.bin> --out <file> --index N|--chip-id 0xNNNN`
  - Extracts a specific patch from EPATCH v1.
  - By default, appends the fw_version like the driver does.

- `scripts/decode_config.py <config.bin>`
  - Parses vendor config if it uses `RTL_CONFIG_MAGIC`.
  - If not, prints raw hex.

## Debug
- `scripts/enable_btrtl_debug.sh`
- `scripts/disable_btrtl_debug.sh`
  - Toggles dynamic debug for `drivers/bluetooth/btrtl.c`.

## Pairing helpers
- `scripts/scan_devices.sh [seconds]`
  - Scans for nearby devices and prints known devices.

- `scripts/pair_device.sh <MAC>`
  - Pairs, trusts, and connects a device (may prompt for PIN/passkey).

- `scripts/setup_autoconnect.sh <MAC>`
  - Installs a systemd autoconnect unit and enables it for the device.

- `scripts/keyboard_info.sh <MAC>`
  - Prints detailed info for a device (Trusted/Connected/etc).

- `scripts/disable_autosuspend.sh`
  - Disables USB autosuspend for the MA530 dongle (2c4e:0115).

- `scripts/install_system_integration.sh <MAC>`
  - Installs system-wide udev + systemd integration (run with `sudo` after a reinstall).

- `scripts/install_user_autoconnect.sh <MAC>`
  - Installs a user-session autoconnect service (no sudo; does not work pre-login).

- `scripts/find_connected_keyboards.sh`
  - Prints detailed info for connected keyboards (Icon: input-keyboard).

## Driver build/install
- `scripts/prepare_source.sh [source-dir]`
  - Validates an out-of-tree `btusb` source directory and applies `patches/btusb-ma530.patch`.
  - Defaults to `${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}`.

- `scripts/build_driver.sh [kver]`
  - Builds `btusb.ko` from `${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}` and copies to `driver/build/<kver>/`.

- `scripts/install_driver.sh [kver]`
  - Installs `btusb.ko` into `/lib/modules/<kver>/updates/` and runs `depmod`.

- `scripts/load_driver.sh [kver]`
  - Reloads `btusb` using the installed module (if present).

- `scripts/unload_driver.sh`
  - Removes `btusb` from the running kernel.

- `scripts/driver_status.sh`
  - Shows which `btusb` module path is active.

## Suggested workflow (quick)
1. `scripts/collect_device_info.sh`
2. `scripts/enable_btrtl_debug.sh`
3. `scripts/capture_btmon.sh` (replug or `scripts/rebind_btusb.sh`)
4. `scripts/parse_rtl_fw.py firmware/rtl8761bu_fw.bin`
5. `scripts/extract_patch.py firmware/rtl8761bu_fw.bin --index 1 --out firmware/rtl8761bu_patch.bin`

- `scripts/keep_bt_connected.sh <MAC>`
  - Loop de keepalive que reconecta quando cair.
