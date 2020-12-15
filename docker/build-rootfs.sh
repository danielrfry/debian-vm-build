#! /bin/bash

set -e

VM_ARCH="$(uname -m)"
VM_ROOTFS_DEV=/dev/loop
VM_ROOTFS_DIR=rootfs
VM_SWAPFILE_PATH=/swapfile
VM_ROOTFS_UUID="$(uuid -v 4)"

# Set root password
echo 'root:password' | chroot "$VM_ROOTFS_DIR" chpasswd

# Set up fstab
cat > "$VM_ROOTFS_DIR/etc/fstab" <<EOF
UUID=$VM_ROOTFS_UUID / ext4 errors=remount-ro 0 1
EOF

# Set hostname
echo "debian-vm-$VM_ARCH" > "$VM_ROOTFS_DIR/etc/hostname"

# Add apt sources
cat > "$VM_ROOTFS_DIR/etc/apt/sources.list" <<EOF
deb http://deb.debian.org/debian buster main
deb http://deb.debian.org/debian-security/ buster/updates main
deb http://deb.debian.org/debian buster-updates main
EOF

# Set up networking
cat > "$VM_ROOTFS_DIR/etc/network/interfaces.d/enp0s1" <<EOF
auto enp0s1
iface enp0s1 inet dhcp
iface enp0s1 inet6 auto
EOF

# Create filesystem image
mkfs.ext4 -d "$VM_ROOTFS_DIR" -U "$VM_ROOTFS_UUID" "$VM_ROOTFS_DEV"
