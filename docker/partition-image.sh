#! /bin/bash

set -e

VM_ARCH="$(uname -m)"
VM_ROOTFS_OUTPUT_DIR=output
VM_ROOTFS_IMG_FILE=$VM_ROOTFS_OUTPUT_DIR/debian-rootfs-$VM_ARCH.img

parted -s "$VM_ROOTFS_IMG_FILE" \
    mklabel gpt \
    mkpart primary ext4 '0%' '100%'
