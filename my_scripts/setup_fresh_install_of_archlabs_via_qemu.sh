#!/usr/bin/env bash
# setup_fresh_install_of_archlabs_via_qemu.sh

# remove previous images if exists
[ -f ~/Downloads/qcow2_archlabs.qcow2 ] && \
rm ~/Downloads/qcow2_archlabs.qcow2 && \
echo "** Old image removed **"

# create new image
qemu-img create -f qcow2 ~/Downloads/archlabs.qcow2 20G
echo "** New image created **"

qemu-system-x86_64 \
-machine type=q35,accel=hvf \
-smp 2 \
-hda ~/Downloads/archlabs.qcow2 \
-cdrom ~/Downloads/archlabs-2021.05.02-x86_64.iso \
-m 4G \
-vga virtio \
-usb \
-device usb-tablet \
-display default,show-cursor=on
