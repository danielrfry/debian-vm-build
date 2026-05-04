#! /bin/bash

set -e

VM_ARCH="$(uname -m)"
VM_OUTPUT_DIR="$(pwd)/output"
VM_ROOTFS_OUTPUT_DIR="$VM_OUTPUT_DIR"
VM_ROOTFS_IMAGE_PATH="$VM_ROOTFS_OUTPUT_DIR/debian-rootfs-$VM_ARCH.img"
VM_ROOTFS_IMAGE_SIZE_GB=10
VM_DOCKER_TAG="debian-vm-build"

function log_stage () {
    echo "$(tput setaf 2; tput bold)$@$(tput sgr0)"
}

function build_kernel () {
    log_stage "Building kernel"
    mkdir -p "$VM_OUTPUT_DIR"
    docker run --rm -i -v "$VM_OUTPUT_DIR":/output "$VM_DOCKER_TAG" ./build-kernel.sh
}

function build_rootfs() {
    log_stage "Building root filesystem"
    mkdir -p "$VM_OUTPUT_DIR"
    docker run --rm -i --privileged -v "$VM_OUTPUT_DIR":/output "$VM_DOCKER_TAG" ./build-rootfs.sh
}

docker build -t "$VM_DOCKER_TAG" docker

build_kernel
build_rootfs
