# Debian VM build scripts
This is a collection of scripts that can be used to build a kernel, initial ram disk and root file system suitable for booting Debian in a virtual machine.

It is intended for use with [toyvm](https://github.com/danielrfry/toyvm) on Apple Silicon (Arm) and Intel Macs, but should work with any `aarch64` or `x86_64` virtual machine that implements virtio devices and supports directly booting a Linux kernel.

Pre-built binaries for Apple Silicon (and other `aarch64` platforms), created using these scripts, are available at [debian-vm-aarch64](https://github.com/danielrfry/debian-vm-aarch64).

## Building
An existing Linux installation of the same architecture as the target is required. For Apple Silicon, this can be a Raspberry Pi 4 running the beta 64-bit version of [Raspberry Pi OS](https://www.raspberrypi.org/forums/viewtopic.php?t=275370).

[Docker](https://www.docker.com) is used to create a consistent build environment. On a Debian-based distribution such as Raspberry Pi OS, install Docker with:

```
sudo apt install docker.io
```

Start the build with:

```
sudo ./build.sh
```

(Root privileges are required to set up a loopback device for populating the disk image, and to issue Docker commands by default).

⚠ **This script tags the Docker images it creates with the names `debian-vm-build-kernel` and `debian-vm-build-rootfs`, overwriting any existing tags with these names.**

### Build times
The table below shows the approximate time taken for a complete build on the systems I've tested with:

|Time               |System                                                       |
|-------------------|-------------------------------------------------------------|
|24 minutes         |Mac mini 2020 (M1), Debian in toyvm, 8GB RAM, 8 CPU cores    |
|47 minutes         |MacBook Pro 2018 (2.3GHz quad core i5), Debian in toyvm, 8GB RAM, 8 CPU cores/threads|
|2 hours, 33 minutes|Raspberry Pi 4B, Raspberry Pi OS 64-bit, 4GB RAM, 4 CPU cores|

This includes the time taken to download Docker images and Debian packages.

## Output
Build products are placed in the `output` subdirectory of the current working directory. The output consists of the following files:

* `deb/` - kernel .deb packages
    * `deb/linux-headers-<version>_arm64.deb`
    * `deb/linux-image-<version>_arm64.deb`
    * `deb/linux-libc-dev_<version>_arm64.deb`
* `debian-rootfs-aarch64.img` - sparse file containing the root filesystem image
* `initrd.img-<version>` - initial ram disk image
* `vmlinuz-<version>` - kernel image

## Configuration
🔑 **The initial root password is `password`.**

The kernel is built with the standard Debian configuration, adjusted to add built-in support for virtio devices (the drivers are normally built as modules).

The root filesystem is generated using `debootstrap`, and as such contains only the bare minimum required to install packages. For convenience, the build scripts configure the virtual network interface and add the standard Debian package sources.

There is no swap configured.

Apple's Virtualization.framework (and therefore toyvm) supports only raw disk image files. To keep disk usage to a minimum, the root filesystem disk image is written to a [sparse file](https://en.wikipedia.org/wiki/Sparse_file).
