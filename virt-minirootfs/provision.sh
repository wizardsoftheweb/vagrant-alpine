#!/bin/sh
#
# Copyright 2020 CJ Harries
# Licensed under http://www.apache.org/licenses/LICENSE-2.0

set -x

# shellcheck disable=SC1091
. blocks
echo "$FILE_POINTER"
echo "$ROOT"

echo "$ROOT / ext4 rw,relatime 0 1" >> /etc/fstab

echo 'nameserver 1.1.1.1' > /etc/resolv.conf
apk update --no-cache
apk add linux-virt syslinux

sed -i -e 's/^default_kernel_opts.*$/default_kernel_opts="cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory"/' -e 's/^root=.*$/root='"$ROOT"'/' /etc/update-extlinux.conf
update-extlinux
