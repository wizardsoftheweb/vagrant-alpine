#!/bin/bash
#
# Copyright 2020 CJ Harries
# Licensed under http://www.apache.org/licenses/LICENSE-2.0

set -x

# Variables to maybe change
DOWNLOADED_TARBALL_NAME="alpine.minirootfs.tar.gz"
CHROOT_DIR="$(pwd)/mnt"

# Variables to probably not change
FILE_DESCRIPTORS=( dev sys proc )
MOUNT_POINTS=()

# Convenience fnc to nuke all the mounts
function unmount_everything {
    for mount_point in "${MOUNT_POINTS[@]}"; do
        sleep 1
        umount -q "$mount_point"
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

function generate_blocks {
    cat <<EOF
FILE_POINTER="${FILE_POINTER}"
ROOT="$(blkid "${FILE_POINTER}p1" --output export | grep --color=never '^UUID')"
EOF
}

# Attempt to gracefully die without leaving hanging loop devices everywhere
# trap unmount_everything EXIT
trap unmount_everything SIGINT

# Get the source tarball
download_alpine_minirootfs

# Prep the image
rm -rf alpine.img
qemu-img create alpine.img 1G

# Create a GPT with a single partition (note its 'Legacy BIOS bootable' flag)
sgdisk --clear \
    --new 1::-0 --typecode=1:8300 --change-name=1:'Linux root filesystem' --attributes=1:set:2 \
    alpine.img

# Create a loop device for the image
FILE_POINTER=$(losetup --show --find alpine.img)

# Update the partition info
partprobe "$FILE_POINTER"

# Format the partitions
mkfs.ext4 -F -L alpineroot "${FILE_POINTER}p1"

# Create and mount the chroot dir
rm -rf "$CHROOT_DIR"
mkdir -p "$CHROOT_DIR"
mount "${FILE_POINTER}p1" "$CHROOT_DIR"

# Install syslinux bootloader files
mkdir -p "$CHROOT_DIR/boot/syslinux"
cp /usr/lib/syslinux/modules/bios/*.c32 "$CHROOT_DIR/boot/syslinux/"
extlinux --install "$CHROOT_DIR/boot/syslinux"
dd bs=440 count=1 conv=notrunc if=/usr/lib/syslinux/mbr/gptmbr.bin of="$FILE_POINTER"

# Populate the chroot dir with minirootfs
mount_file_descriptors "$CHROOT_DIR"
tar -zxf "$DOWNLOADED_TARBALL_NAME" -C "$CHROOT_DIR/"
cp provision.sh "$CHROOT_DIR/"
generate_blocks > "$CHROOT_DIR/blocks"

# Run a provisioning script
chroot "$CHROOT_DIR" /provision.sh

# sudo qemu-system-x86_64 -drive format=raw,file=alpine.img -serial stdio -m 4G -cpu host -smp 2 -enable-kvm
