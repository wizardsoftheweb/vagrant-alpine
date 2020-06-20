#!/bin/bash
#
# Copyright 2020 CJ Harries
# Licensed under http://www.apache.org/licenses/LICENSE-2.0

set -xe

# Variables to maybe change
DOWNLOADED_TARBALL_NAME="alpine.minirootfs.tar.gz"
CHROOT_DIR="$(pwd)/mnt"

# Variables to probably not change
FILE_DESCRIPTORS=( dev sys proc )
MOUNT_POINTS=()

# Convenience fnc to nuke all the mounts
function unmount_everything {
    for mount_point in "${MOUNT_POINTS[@]}"; do
        umount -q "$mount_point"
        sleep 1
    done
    umount -q "$CHROOT_DIR"
    if [[ -n ${FILE_POINTER+x} ]]; then
        losetup -d "$FILE_POINTER"
    fi
}

# Convenience fnc to mount all system fds
function mount_file_descriptors {
    mount_dir=${1:-$CHROOT_DIR}
    for fd in "${FILE_DESCRIPTORS[@]}"; do
        mkdir -p "$mount_dir/$fd"
        mount --bind "/$fd" "$mount_dir/$fd"
        MOUNT_POINTS+=( "$mount_dir/$fd" )
    done
}

# Fnc to download the necessary source tarball
function download_alpine_minirootfs {
    if [ ! -f "$DOWNLOADED_TARBALL_NAME" ]; then
        curl -fL http://dl-cdn.alpinelinux.org/alpine/v3.12/releases/x86_64/alpine-minirootfs-3.12.0-x86_64.tar.gz -o $DOWNLOADED_TARBALL_NAME
    fi
}

# Attempt to gracefully die without leaving hanging loop devices everywhere
trap unmount_everything EXIT
trap unmount_everything SIGINT

# Get the source tarball
download_alpine_minirootfs

# Prep the image
rm -rf alpine.img
qemu-img create alpine.img 1G

# Create a loop device for the image
FILE_POINTER=$(losetup --partscan --show --find alpine.img)

# Partition the file
# https://blog.heckel.io/2017/05/28/creating-a-bios-gpt-and-uefi-gpt-grub-bootable-linux-system/#Creating-a-GPT-with-a-BIOS-boot-partition-and-an-EFI-System-Partition
sgdisk --clear \
  --new 1::+1M   --typecode=1:ef02 --change-name=1:'BIOS boot partition' \
  --new 2::+100M --typecode=2:ef00 --change-name=2:'EFI System' \
  --new 3::-0    --typecode=3:8300 --change-name=3:'Linux root filesystem' \
  "$FILE_POINTER"

# Update the partition info
partprobe "$FILE_POINTER"

# Format the partitions
# The first partition is left alone for grub's core.img
mkfs.fat  -F32 "${FILE_POINTER}p2"
mkfs.ext4 -F   "${FILE_POINTER}p3"

# Create and populate the chroot dir
mkdir -p "$CHROOT_DIR"
mount "${FILE_POINTER}p3" "$CHROOT_DIR"
mount_file_descriptors "$CHROOT_DIR"
tar -zxf "$DOWNLOADED_TARBALL_NAME" -C "$CHROOT_DIR"
cp provision.sh "$CHROOT_DIR/"

chroot "$CHROOT_DIR" /provision.sh
