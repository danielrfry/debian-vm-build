#! /bin/bash

set -e

VM_ARCH="$(uname -m)"
VM_ROOTFS_DEV=/dev/loop
VM_ROOTFS_DIR=rootfs
VM_SWAPFILE_PATH=/swapfile
VM_ROOTFS_UUID="$(uuid -v 4)"
VM_TEMP_VOLUME_DIR="temp-volume"
VM_DEFAULT_HOSTNAME="debian-vm-${VM_ARCH//_/-}"

# Set root password
echo 'root:password' | chroot "$VM_ROOTFS_DIR" chpasswd

# Set up fstab
cat > "$VM_ROOTFS_DIR/etc/fstab" <<EOF
UUID=$VM_ROOTFS_UUID / ext4 errors=remount-ro 0 1
EOF

# Set hostname
echo "$VM_DEFAULT_HOSTNAME" > "$VM_ROOTFS_DIR/etc/hostname"

# Add apt sources
cat > "$VM_ROOTFS_DIR/etc/apt/sources.list" <<EOF
deb http://deb.debian.org/debian bullseye main
deb http://deb.debian.org/debian-security/ bullseye/updates main
deb http://deb.debian.org/debian bullseye-updates main
EOF

# Set up networking
cat > "$VM_ROOTFS_DIR/etc/network/interfaces.d/enp0s1" <<EOF
auto enp0s1
iface enp0s1 inet dhcp
iface enp0s1 inet6 auto
EOF

# Install kernel package
cp "$VM_TEMP_VOLUME_DIR"/linux-image-*.deb "$VM_ROOTFS_DIR/linux-image.deb"
chroot "$VM_ROOTFS_DIR" dpkg -i /linux-image.deb
rm "$VM_ROOTFS_DIR/linux-image.deb"

# Create filesystem image
mkfs.ext4 -d "$VM_ROOTFS_DIR" -U "$VM_ROOTFS_UUID" "$VM_ROOTFS_DEV"
