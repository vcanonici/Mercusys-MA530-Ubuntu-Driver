# MA530 RE - Driver Plan (Realtek RTL8761BU)

## Goal
Create a minimal, working Linux driver path for the MA530 dongle (2c4e:0115) that:
- enumerates the device,
- loads firmware,
- registers an HCI controller,
- allows pairing a Bluetooth keyboard via BlueZ.

## Phase 0: Define success criteria
- Confirm exact use-case (only HID keyboard? BLE? Classic?).
- Define what "done" means (pair/connect, stable reconnect, no errors in dmesg).

## Phase 1: Capture ground truth
- Collect baseline logs and descriptors:
  - `scripts/collect_device_info.sh`
- Capture HCI traffic during attach/firmware download:
  - `scripts/enable_btrtl_debug.sh`
  - `scripts/capture_btmon.sh` (replug dongle or `scripts/rebind_btusb.sh`)
- Optional USB-level capture (usbmon + Wireshark) to see raw URBs.

Deliverables:
- Logs in `logs/<timestamp>/`
- btmon `.btsnoop` capture with a clean attach sequence

## Phase 2: Firmware and config understanding
- Parse EPATCH and identify the active patch:
  - `scripts/parse_rtl_fw.py firmware/rtl8761bu_fw.bin`
  - `scripts/extract_patch.py ... --index 1 --out firmware/rtl8761bu_patch.bin`
- Verify project_id and patch offsets vs. `btrtl.c` logic.
- Check config blob contents with `scripts/decode_config.py` (even if optional).

Deliverables:
- Documented patch metadata and chosen patch in `notes/firmware-inspection.md`

## Phase 3: Driver strategy
Two viable paths:

A) Extend existing kernel drivers (recommended)
- Leverage btusb + btrtl (already supports RTL8761BU).
- If MA530 VID/PID ever fails to bind, add an ID quirk.
- Keep most logic in upstream drivers; only add minimal changes.

B) Out-of-tree driver (learning-focused)
- Clone btusb/btrtl logic into a small kernel module:
  - USB probe + interface matching
  - Firmware load via request_firmware
  - HCI registration
- Bind only to 2c4e:0115.

Deliverables:
- A minimal module that enumerates and registers `hci0`.

## Phase 4: Implement and test
- Build module (Makefile + DKMS optional).
- Load/unload and validate:
  - `dmesg` shows firmware download + HCI ready
  - `bluetoothctl show` works
  - Pair/connect keyboard

Deliverables:
- Test log and reproducible steps to pair a keyboard

## Phase 5: Stabilization and improvements
- Add logging for errors/timeouts (URB resubmit, vendor command failures).
- Handle reconnect and suspend/resume paths.
- Optional: add debugfs or module params for tuning.

## Risks
- Firmware is closed; patching is high risk.
- A broken driver can leave the adapter non-functional until replug.
- Some features may remain vendor-locked.
