#!/bin/bash
#
# Copyright 2020 CJ Harries
# Licensed under http://www.apache.org/licenses/LICENSE-2.0

umount mnt/{boot,dev,proc}
umount mnt
losetup -d $( losetup --list --noheadings --output NAME | sort -V -r | head -n 1 )
