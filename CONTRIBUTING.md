# Contributing

Useful reports are reproducible and sanitized.

## Before Opening An Issue

Run:

```bash
uname -r
modinfo -n btusb
modinfo /lib/modules/$(uname -r)/updates/btusb.ko | rg -n 'srcversion|vermagic|version'
lsmod | rg -n '^btusb|^btrtl|^bluetooth'
lsusb | rg -i '2c4e:0115|mercusys'
bluetoothctl show
```

Remove private hostnames, Bluetooth MAC addresses, serial numbers, and personal device names before posting output.

## Pull Requests

- Keep changes scoped to MA530 / RTL8761BU Linux support.
- Do not add firmware blobs or generated `.ko` files.
- Keep scripts POSIX-friendly where practical, but Bash is acceptable for existing scripts.
- Include the kernel version and distribution used for testing.
