# Reinstall Checklist (Ubuntu)

After a fresh OS install, Bluetooth pairing data and the system integrations are gone.

## 1) Verify the dongle is detected
```
lsusb | rg -n "2c4e:0115"
```

## 2) Ensure Bluetooth service is running
```
systemctl is-enabled bluetooth
systemctl is-active bluetooth
```

## 3) Pair and connect the keyboard (once)
Put the keyboard in pairing mode, then:
```
./scripts/scan_devices.sh 15
./scripts/pair_device.sh <MAC>
```

## 4) Make it reconnect automatically
### Preferred (system-wide; needs sudo)
```
sudo ./scripts/install_system_integration.sh <MAC>
```

### Fallback (user session only; no sudo)
This won't work pre-login, but helps for lock screen in an already logged-in session:
```
./scripts/install_user_autoconnect.sh <MAC>
```

## 5) Prevent USB autosuspend (needs sudo)
```
sudo ./scripts/disable_autosuspend.sh
```

## Notes
- Bluetooth keyboards do not work in BIOS/GRUB/LUKS prompts unless the keyboard supports USB HID proxy or you use a 2.4GHz receiver.
