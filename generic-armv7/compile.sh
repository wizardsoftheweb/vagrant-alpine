#!/bin/bash

# curl -fL http://dl-cdn.alpinelinux.org/alpine/v3.12/releases/armv7/alpine-uboot-3.12.0-armv7.tar.gz -o alpine-uboot.tgz

set -xe

FILE_DESCRIPTORS=( dev sys proc )
MOUNT_POINTS=()

function unmount_everything {
    if [ ! -z ${FILE_POINTER+x} ]; then
        losetup -d $FILE_POINTER
    fi
    for mount_point in "${MOUNT_POINTS[@]}"; do
        umount -q $mount_point
    done
}

function mount_file_descriptors {
    mount_dir=${1:mnt}
    for fd in "${FILE_DESCRIPTOS[@]}"; do
        mount --bind /$fd ${mount_dir}/$fd
        MOUNT_POINTS+=(${mount_dir}/$fd)
    done
}

trap unmount_everything EXIT
trap unmount_everything SIGINT

# Prep the image
rm -rf generic-armv7.img
qemu-img create generic-armv7.img 1G

FILE_POINTER=$(losetup --partscan --show --find generic-armv7.img)

# Partition the file
# https://blog.heckel.io/2017/05/28/creating-a-bios-gpt-and-uefi-gpt-grub-bootable-linux-system/#Creating-a-GPT-with-a-BIOS-boot-partition-and-an-EFI-System-Partition
sgdisk --clear \
  --new 1::+1M   --typecode=1:ef02 --change-name=1:'BIOS boot partition' \
  --new 2::+100M --typecode=2:ef00 --change-name=2:'EFI System' \
  --new 3::-0    --typecode=3:8300 --change-name=3:'Linux root filesystem' \
  $FILE_POINTER

# Update the partition info
partprobe $FILE_POINTER

# Format format the partitions
# The first partition is left alone for grub's core.img
mkfs.fat  -F32 ${FILE_POINTER}p2
mkfs.ext4 -F   ${FILE_POINTER}p3
