#! /bin/bash

set -eux

source "$(dirname "$0")/common.inc.sh"

VM_ROOTFS_OUTPUT_DIR="$VM_OUTPUT_DIR"
VM_ROOTFS_IMAGE_PATH="$VM_ROOTFS_OUTPUT_DIR/debian-rootfs-$VM_ARCH.img"
VM_ROOTFS_IMAGE_SIZE_GB=10
VM_ROOTFS_STAGING_DIR="$VM_BUILD_DIR/rootfs"
VM_ROOTFS_DEV=/dev/loop
VM_ROOTFS_UUID="$(uuid -v 4)"
VM_DEFAULT_HOSTNAME="debian-vm-${VM_ARCH//_/-}"

log_stage "Building root filesystem"

mkdir -p "$VM_ROOTFS_STAGING_DIR"
debootstrap trixie "$VM_ROOTFS_STAGING_DIR" https://deb.debian.org/debian/

# Set up fstab
cat > "$VM_ROOTFS_STAGING_DIR/etc/fstab" <<EOF
UUID=$VM_ROOTFS_UUID / ext4 errors=remount-ro 0 1
EOF

# Set up machine ID and firstboot configuration
systemd-firstboot --force --root="$VM_ROOTFS_STAGING_DIR" --root-password=password --locale=C.UTF-8 \
    --timezone=UTC --hostname="$VM_DEFAULT_HOSTNAME" --root-shell=/bin/bash
rm -f "$VM_ROOTFS_STAGING_DIR/etc/machine-id"
echo -e "127.0.1.1\t$VM_DEFAULT_HOSTNAME ${VM_DEFAULT_HOSTNAME}.local" >> "$VM_ROOTFS_STAGING_DIR/etc/hosts"

# Add apt sources
cat > "$VM_ROOTFS_STAGING_DIR/etc/apt/sources.list" <<EOF
deb http://deb.debian.org/debian trixie main
deb http://deb.debian.org/debian-security/ trixie-security main
deb http://deb.debian.org/debian trixie-updates main
EOF

# Set up networking
cat > "$VM_ROOTFS_STAGING_DIR/etc/network/interfaces.d/enp0s1" <<EOF
allow-hotplug enp0s1
auto enp0s1
iface enp0s1 inet dhcp
iface enp0s1 inet6 auto
EOF

cat > "$VM_ROOTFS_STAGING_DIR/etc/network/interfaces.d/lo" <<EOF
auto lo
iface lo inet loopback
EOF

# Install kernel package
cp "$VM_OUTPUT_DIR"/deb/linux-image-*.deb "$VM_ROOTFS_STAGING_DIR/linux-image.deb"
chroot "$VM_ROOTFS_STAGING_DIR" dpkg -i /linux-image.deb
rm "$VM_ROOTFS_STAGING_DIR/linux-image.deb"

# Create disk image
dd if=/dev/zero bs=1G count=0 seek=$VM_ROOTFS_IMAGE_SIZE_GB of="$VM_ROOTFS_IMAGE_PATH"

# Partition image
parted -s "$VM_ROOTFS_IMAGE_PATH" \
    mklabel gpt \
    mkpart primary ext4 '0%' '100%'

VM_ROOTFS_DEV="$(retry_command 5 2 losetup -P -f --show "$VM_ROOTFS_IMAGE_PATH")"
VM_ROOTFS_PARTITION_DEV="${VM_ROOTFS_DEV}p1"
trap "losetup -d $VM_ROOTFS_DEV" EXIT

if [[ ! -b "$VM_ROOTFS_PARTITION_DEV" ]]; then
    mknod "$VM_ROOTFS_PARTITION_DEV" b $(lsblk -nlo MAJ,MIN -Q "PATH=='$VM_ROOTFS_PARTITION_DEV'")
fi

# Create filesystem image
mkfs.ext4 -d "$VM_ROOTFS_STAGING_DIR" -U "$VM_ROOTFS_UUID" "$VM_ROOTFS_PARTITION_DEV"
