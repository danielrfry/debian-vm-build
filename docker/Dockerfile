FROM debian:trixie AS debian-vm-build
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y build-essential linux-source kmod cpio initramfs-tools fakeroot libssl-dev lsb-release openssl libelf-dev rsync python3 debootstrap parted uuid udev debhelper-compat e2fsprogs
WORKDIR /root
COPY common.inc.sh build-kernel.sh partition-image.sh build-rootfs.sh ./
CMD mkdir -p /build /output
