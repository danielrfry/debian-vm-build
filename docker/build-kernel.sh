#! /bin/bash

set -e

VM_LINUX_SRC_ARCHIVE=/usr/src/linux-source-*.tar.xz
VM_BUILD_DIR="linux-build"
VM_OUTPUT_DIR="output"
VM_KERNEL_OUTPUT_DIR="$VM_OUTPUT_DIR"
VM_INITRD_OUTPUT_DIR="$VM_OUTPUT_DIR"
VM_DEB_OUTPUT_DIR="$VM_OUTPUT_DIR/deb"
VM_TEMP_VOLUME_DIR="temp-volume"
VM_ARCH="$(uname -m)"

if [[ "$VM_ARCH" == "aarch64" ]]; then
    VM_CONFIG_PATH=/usr/src/linux-config-*/config.arm64_none_arm64.xz
elif [[ "$VM_ARCH" == "x86_64" ]]; then
    VM_CONFIG_PATH=/usr/src/linux-config-*/config.amd64_none_amd64.xz
else
    echo "Unsupported architecture: $VM_ARCH" >&2
    exit 1
fi

function log_step () {
    echo "$(tput setaf 4)$@$(tput sgr0)"
}

mkdir -p $VM_BUILD_DIR
pushd $VM_BUILD_DIR

log_step "Unpacking kernel source code"
tar -xJf $VM_LINUX_SRC_ARCHIVE

log_step "Building kernel"
cd linux-source-*
xz -d < $VM_CONFIG_PATH > .config
scripts/config \
    -d CONFIG_DEBUG_INFO \
    -e CONFIG_VIRTIO \
    -e CONFIG_VIRTIO_PCI \
    -e CONFIG_VIRTIO_CONSOLE \
    -e CONFIG_VIRTIO_BALLOON \
    -e CONFIG_VIRTIO_BLK \
    -e CONFIG_VIRTIO_NET \
    --set-str CONFIG_BUILD_SALT '' \
    -e CONFIG_MODULE_SIG_ALL \
    --set-str CONFIG_MODULE_SIG_KEY 'certs/signing_key.pem' \
    --set-str CONFIG_SYSTEM_TRUSTED_KEYS ''
make -j `nproc` deb-pkg

popd

echo 'RESUME=none' > /etc/initramfs-tools/conf.d/resume

log_step "Installing kernel package"
dpkg -i $VM_BUILD_DIR/linux-image-*.deb

log_step "Copying build output to host"
mkdir -p $VM_KERNEL_OUTPUT_DIR
VM_KERNEL_IMAGE_SRC_PATH=/boot/vmlinuz-*
if [[ "$VM_ARCH" == "aarch64" ]]; then
    VM_KERNEL_IMAGE_NAME=$(basename $VM_KERNEL_IMAGE_SRC_PATH)
    VM_KERNEL_IMAGE_DEST_PATH=$VM_KERNEL_OUTPUT_DIR/$VM_KERNEL_IMAGE_NAME
    gunzip < $VM_KERNEL_IMAGE_SRC_PATH > $VM_KERNEL_IMAGE_DEST_PATH
else
    cp $VM_KERNEL_IMAGE_SRC_PATH $VM_KERNEL_OUTPUT_DIR/
fi

mkdir -p $VM_INITRD_OUTPUT_DIR
cp /boot/initrd.img-* $VM_INITRD_OUTPUT_DIR/

mkdir -p $VM_DEB_OUTPUT_DIR
cp $VM_BUILD_DIR/*.deb $VM_DEB_OUTPUT_DIR/

cp $VM_BUILD_DIR/linux-image-*.deb $VM_TEMP_VOLUME_DIR/
