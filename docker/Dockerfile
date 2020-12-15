FROM debian:buster AS debian-vm-build-base
WORKDIR /root
RUN apt-get update && apt-get upgrade -y

FROM debian-vm-build-base AS debian-vm-build-kernel
WORKDIR /root
RUN apt-get install -y build-essential linux-source kmod cpio initramfs-tools fakeroot libssl-dev lsb-release openssl
COPY build-kernel.sh ./
CMD ./build-kernel.sh

FROM debian-vm-build-base AS debian-vm-build-rootfs
WORKDIR /root
RUN apt-get install -y debootstrap parted uuid udev
RUN debootstrap buster rootfs https://deb.debian.org/debian/
COPY partition-image.sh build-rootfs.sh ./
CMD ./build-rootfs.sh
