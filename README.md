# Debian VM build scripts
This is a collection of scripts that can be used to build a kernel, initial ram disk and root file system suitable for booting Debian in a virtual machine.

It is intended for use with [toyvm](https://github.com/danielrfry/toyvm) on Apple Silicon (Arm) and Intel Macs, but should work with any `aarch64` or `x86_64` virtual machine that implements virtio devices and supports directly booting a Linux kernel.

See [Releases](https://github.com/danielrfry/debian-vm-build/releases) for pre-built binaries for Apple Silicon (and other `aarch64` platforms), created using these scripts.

## Building
An existing Linux installation of the same architecture as the target is required. For Apple Silicon, this can be a Raspberry Pi 4 or later running the **64-bit version** of [Raspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/).

[Docker](https://www.docker.com) is used to create a consistent build environment. On a Debian-based distribution such as Raspberry Pi OS, install Docker with:

```
sudo apt install docker.io
```

Start the build with:

```
sudo ./build.sh
```

(Root privileges are required to issue Docker commands by default).

> [!WARNING]
> This script tags the Docker image it creates with the name `debian-vm-build`, overwriting any existing tag with this name.

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

> [!NOTE]
> 🔑 The initial root password is `password` - don't forget to change it.

The kernel is built with the standard Debian configuration, adjusted to add built-in support for virtio devices (the drivers are normally built as modules).

The root filesystem is generated using `debootstrap`, and as such contains only the bare minimum required to install packages. For convenience, the build scripts configure the virtual network interface and add the standard Debian package sources.

There is no swap configured.

To keep disk usage to a minimum, the root filesystem disk image is written to a [sparse file](https://en.wikipedia.org/wiki/Sparse_file).

## Booting in toyvm
```
tar xvJf debian-vm-aarch64_*.tar.xz
toyvm -k vmlinuz-* -i initrd.img-* -d debian-rootfs-aarch64.img 'console=hvc0 root=/dev/vda1 rw'
```

## Enlarging the root filesystem
With the VM stopped, first increase the size of the disk image file (20GB in this example):

```
$ dd if=/dev/zero of=debian-rootfs-aarch64.img bs=1g count=0 seek=20
```

Inside the VM, assuming the first virtual disk contains the root filesystem, resize the partition to fill the entire disk image:

```
# apt install parted
# parted /dev/vda
GNU Parted 3.2
Using /dev/vda
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) resizepart
Warning: Not all of the space available to /dev/vda appears to be used, you can
fix the GPT to use all of the space (an extra 20971520 blocks) or continue with
the current setting?
Fix/Ignore? Fix
Partition number? 1
Warning: Partition /dev/vda1 is being used. Are you sure you want to continue?
Yes/No? Yes
End?  [10.7GB]? 100%
(parted) quit
Information: You may need to update /etc/fstab.
```

Finally, resize the filesystem:

```
# resize2fs /dev/vda1
```
