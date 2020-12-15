#! /bin/bash

set -e

VM_ARCH="$(uname -m)"
VM_OUTPUT_DIR="$(pwd)/output"
VM_ROOTFS_OUTPUT_DIR="$VM_OUTPUT_DIR"
VM_ROOTFS_IMAGE_PATH="$VM_ROOTFS_OUTPUT_DIR/debian-rootfs-$VM_ARCH.img"
VM_ROOTFS_IMAGE_SIZE_GB=10
VM_DOCKER_TAG_BUILD_KERNEL="debian-vm-build-kernel"
VM_DOCKER_TAG_BUILD_ROOTFS="debian-vm-build-rootfs"

function log_stage () {
    echo "$(tput setaf 4; tput bold)$@$(tput sgr0)"
}

function build_kernel () {
    log_stage "Preparing kernel build environment"
    docker build --target debian-vm-build-kernel -t "$VM_DOCKER_TAG_BUILD_KERNEL" docker

    log_stage "Building kernel"
    mkdir -p "$VM_OUTPUT_DIR"
    docker run --rm -it -v "$VM_OUTPUT_DIR":/root/output --mount source="$VM_TEMP_VOLUME",destination=/root/temp-volume "$VM_DOCKER_TAG_BUILD_KERNEL"
}

function build_rootfs() {
    log_stage "Preparing root filesystem build environment"
    docker build --target debian-vm-build-rootfs -t "$VM_DOCKER_TAG_BUILD_ROOTFS" docker

    log_stage "Creating root filesystem image file"
    mkdir -p "$VM_ROOTFS_OUTPUT_DIR"
    dd if=/dev/zero bs=1G count=0 seek=$VM_ROOTFS_IMAGE_SIZE_GB of="$VM_ROOTFS_IMAGE_PATH"
    
    docker run --rm -it -v "$VM_OUTPUT_DIR":/root/output "$VM_DOCKER_TAG_BUILD_ROOTFS" ./partition-image.sh

    log_stage "Building root filesystem"
    VM_ROOTFS_DEV="$(losetup -P -f --show "$VM_ROOTFS_IMAGE_PATH")"
    VM_ROOTFS_PARTITION_DEV="${VM_ROOTFS_DEV}p1"
    trap "losetup -d $VM_ROOTFS_DEV" RETURN

    docker run --rm -it --device="$VM_ROOTFS_PARTITION_DEV:/dev/loop" --mount source="$VM_TEMP_VOLUME",destination=/root/temp-volume "$VM_DOCKER_TAG_BUILD_ROOTFS"
}

VM_TEMP_VOLUME="$(docker volume create)"
trap "docker volume rm $VM_TEMP_VOLUME" EXIT

build_kernel
build_rootfs
