#!/bin/bash
#
# Copyright 2020 CJ Harries
# Licensed under http://www.apache.org/licenses/LICENSE-2.0

set -x

umount -q mnt/{dev,proc,sys,boot/EFI}
umount -q mnt
losetup -d "$( losetup --list --noheadings --output NAME | sort -V -r | head -n 1 )"

losetup -f
