#!/bin/bash

usage() {
	echo
	echo "usage: $0 DEVICE"
	echo "       sudo $0 /dev/sdX"
	echo
}

if [ -z "$1" ]; then
	echo "Must specify a device"
	usage
	exit 1
fi

set -ex

DEV=$1
MNT=$(mktemp -d)
BASE=$(readlink -f -- $(dirname -- $0))


umount ${DEV}? || true

#
# Create GUID partition table like this:
#
#Number  Start (sector)    End (sector)  Size       Code  Name
#   1              34            2047   1007.0 KiB  EF02  
#   2            2048           65535   31.0 MiB    EF00  
#   3           65536         4194303   2.0 GiB     8300 
sgdisk --zap-all $DEV
sgdisk --set-alignment=1 --new=1:34:2047 --typecode=1:0xef02 $DEV
sgdisk --new=2:2048:65535 --typecode=2:0xef00 --new=3:65536:4194303 $DEV

mkfs.vfat -n LIVE_BOOT ${DEV}2
mkfs.vfat -n LIVE_IMGS ${DEV}3

mkdir -p $MNT
mount ${DEV}2 $MNT

GRUB_INSTALL_OPTS="--recheck --efi-directory=$MNT --boot-directory=$MNT --removable $DEV --themes=\"\""

grub-install $GRUB_INSTALL_OPTS \
	--target=i386-pc #2>&1 | tee grub-install.i386.log

grub-install $GRUB_INSTALL_OPTS \
	--target=x86_64-efi #2>&1 | tee grub-install.x86_64.log

cp $BASE/grub.cfg $MNT/grub/grub.cfg

umount $MNT
rm -rf $MNT
