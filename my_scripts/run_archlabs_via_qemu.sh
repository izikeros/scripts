#!/usr/bin/env bash
# run_archlabs_via_qemu.sh

qemu-system-x86_64 \
-machine type=q35,accel=hvf \
-smp 2 \
-hda ~/Downloads/archlabs.qcow2 \
-m 4G \
-vga virtio \
-usb \
-device usb-tablet \
-display default,show-cursor=on