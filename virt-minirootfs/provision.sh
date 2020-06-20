#!/bin/sh
#
# Copyright 2020 CJ Harries
# Licensed under http://www.apache.org/licenses/LICENSE-2.0

set -xe

# shellcheck disable=SC1091
. blocks
echo "$FILE_POINTER"
echo "$BOOT"
echo "$ROOT"

echo "$ROOT /         ext4 rw,relatime 0 1" >> /etc/fstab
echo "$BOOT /boot/EFI ext4 rw,relatime 0 2" >> /etc/fstab

echo 'nameserver 1.1.1.1' > /etc/resolv.conf
apk update --no-cache
apk add linux-virt

# apk add grub grub-bios
# grub-install --modules="ext2 part_gpt" --target=i386-pc "$FILE_POINTER"
grub-install --force --target=x86_64-efi --efi-directory=/boot/EFI --boot-directory=/boot
