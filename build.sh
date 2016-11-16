#!/bin/bash
set -e

PROJECT_VERSION="0.1.0"

BUSYBOX_VERSION="1.21.1"
BUSYBOX_BASE_URL="https://busybox.net/downloads/binaries/$BUSYBOX_VERSION"
declare -A BUSYBOX_MD5=(
	["armv6l"]="d9b9d2245c2df526a8e373340f1e3b5a"
	["i686"]="130e3ccda88aa313faee5be1af8ec21b"
	["x86_64"]="d1a32f63fef8e639a63d85e46753c0ae" )

function verifyBusybox {
	arch=$1
	md5=($(md5sum busybox-cache/busybox-$arch))
	if [[ $md5 != ${BUSYBOX_MD5[$arch]} ]]; then
		return 1
	fi
}

# Clean
if [ -e target ]; then
    rm -rf target
fi
mkdir target
mkdir -p busybox-cache

# Build image for each arch
for arch in ${!BUSYBOX_MD5[@]}; do
	# Download/verify busybox binaries
	if ! verifyBusybox $arch; then
		echo "File busybox-$arch does not exist or failed checksum validation, downloading..."
		wget $BUSYBOX_BASE_URL/busybox-$arch -O busybox-cache/busybox-$arch
		if ! verifyBusybox $arch; then
			echo "Checksum validation failed for busybox-$arch" >&2
			exit 1
		fi
	fi
	
	# Create base
	INIT_DIR=target/$arch
	mkdir -p $INIT_DIR/{boot,bin,dev,etc,lib,mnt,proc,sbin,sys,tmp}
	cp -rf src/* $INIT_DIR
	cp -f busybox-cache/busybox-$arch $INIT_DIR/bin/busybox
	chmod 755 $INIT_DIR/bin/busybox
	for bbcmd in $($INIT_DIR/bin/busybox --list); do
	    ln -s busybox $INIT_DIR/bin/$bbcmd
	done
	cd $INIT_DIR
	find . | cpio -H newc -o --owner=0:0 | gzip > ../init-$PROJECT_VERSION-$arch.gz
	cd ../..

	# Create debug (start shell before switching root, start shell on error instead of exiting)
	cp -r $INIT_DIR $INIT_DIR-debug
	INIT_DIR=$INIT_DIR-debug
	sed -i -r '/# End mounting OS filesystems/a sh' $INIT_DIR/init
	sed -i -r 's/exit 1/sh/' $INIT_DIR/init
	cd $INIT_DIR
	find . | cpio -H newc --owner=0:0 -o | gzip > ../init-$PROJECT_VERSION-$arch-debug.gz
	cd ../..
done
