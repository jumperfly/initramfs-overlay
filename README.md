# initramfs-overlay
Initramfs focussed on mounting a read only image with writeable overlay using overlayfs.

## Disk partitions
The following disk partitions are expected, currently located by label:
* The image partition (ext4,LABEL=img): Contains the OS squashfs image to mount and boot.
* The overlay partition (ext4,LABEL=overlay): Writeable partition overlaid with the OS image, cleared each boot.
* The boot partition (vfat,LABEL=boot): Optional for initframfs, contains the kernel plus squashfs module (if not in kernel).
* The new image partition (ext4,LABEL=newimg): Optional, can be used to provide an updated OS image.

### The boot partition
If the partition is detected, the squashfs module will be loaded from /modules/<kernel-version>/squashfs.ko if the module existed. Otherwise it is assumed the kernel has build-in support for squashfs.

### The overlay partition
This is used as the writeable area of the overlay and consists of three directories which are created if not preset:
* /upper: Used for the 'upperdir' of the overlayfs. This is where all deleted/modified/created files are stored. This is cleared on each boot.
* /work: Used for the 'workdir' of the overlayfs.
* /persistent: Used as an additional 'lowerdir' of the overlayfs. As the 'upperdir' is cleared, this read-only lower dir allows customisations to be made compared to the read-only OS image.

### The image partition
This must contain a single file, root-squashfs.img which contains the full operating system.

### The new image partition.
If the partition is detected and contains an image file with the same name as the one that will be mounted from the image partition it will be moved into the image partition. The previous image will be renamed <name>-old.img

## Project structure
The build.sh script will generate two initramfs files per architecture into a 'target' directory.
* init-<version>-<arch>.gz - The 'standard' initramfs. This should be used in most cases.
* init-<version>-<arch>-debug.gz - The 'debug' initramfs. This will load a shell before booting to allow any checks to made, type 'exit' to boot. Also it will load a shell if an error occurs, rather than exiting immediately resulting in a shutdown.

Currently three architectures are built:
* armv6l
* i686
* x86_64

The build will include all files under 'src' in the intramfs. A busybox binary (cached into 'busybox-cache') is also placed under /bin/busybox and corresponding symlinks for all commands supported by busybox.
