# Vendor Support Context

This repository exists because the Mercusys MA530 is sold with official Windows support, but not official Linux support.

## Official Mercusys Product Page

The official MA530 page lists:

- Product: MA530 Bluetooth Nano USB Adapter
- Supported operating system: Windows 11/10/8.1/7
- Bluetooth path: consumer PC/laptop Bluetooth adapter

Source:

- https://www.mercusys.com/en/product/adapter/ma530/v1/

## Mercusys Operating-System Compatibility FAQ

Mercusys publishes an operating-system compatibility table for network adapters. In that table:

- MA530 appears as a Bluetooth 5.4 Nano USB Adapter.
- Windows support is listed as Windows 11/10/8.1/7.
- Linux support is marked as unsupported.
- The FAQ also says Mercusys adapters do not support macOS.

Source:

- https://www.mercusys.com.mx/faq-1422/

## Project Position

This is not an official Mercusys, Realtek, or Linux kernel project.

This is a community repair path for Linux users who already own the MA530 and want their hardware to work. The project patches Linux `btusb` handling for USB ID `2c4e:0115` so the adapter follows the Realtek RTL8761BU / RTL8761BUV Bluetooth path.
