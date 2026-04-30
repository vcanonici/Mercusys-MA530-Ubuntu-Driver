# MA530 Driver Build (btusb out-of-tree)

## Summary
- Custom btusb built from `/usr/src/btusb-4.3` with small MA530 log and updated quirk API.
- Installed into `/lib/modules/<kver>/updates/` and loaded via `modprobe`.

## Patches applied
- Added MA530 vendor/product constants and log in `btusb_probe`:
  - Logs: `MA530: binding RTL8761BU via btusb`
- Updated old quirk API:
  - `set_bit(..., &hdev->quirks)` -> `hci_set_quirk(hdev, ...)`
  - `clear_bit(..., &hdev->quirks)` -> `hci_clear_quirk(hdev, ...)`
- Makefile fix: use `$(CURDIR)` instead of `$(PWD)` for out-of-tree build.

## Build/Install
```
./scripts/build_driver.sh
./scripts/install_driver.sh
./scripts/load_driver.sh
```

## Verify
```
./scripts/driver_status.sh
sudo dmesg | tail -n 80 | rg -i "MA530|RTL|btusb"
```

## Current kernel
```
6.14.0-37-generic
```
