#!/bin/bash
#
# Copyright 2020 CJ Harries
# Licensed under http://www.apache.org/licenses/LICENSE-2.0

set -xe

# Create a raw image
rm -rf alpine.img
qemu-img create alpine.img 1G

# Get a reference to the image
FILE_POINTER=$(losetup --partscan --show --find alpine.img)

# Partition and format the image
sfdisk $FILE_POINTER < mbr.out
mkfs.fat -F32 ${FILE_POINTER}p1
mkfs.ext4 ${FILE_POINTER}p2

# Set up mounts
mkdir -p mnt
mount ${FILE_POINTER}p2 mnt
mkdir mnt/{boot,dev,proc}
mount ${FILE_POINTER}p1 mnt/boot
mount -t proc none mnt/proc
mount -o bind /dev mnt/dev
ln -s /sys mnt/sys

cd mnt

# Create minirootfs
curl -fL http://dl-cdn.alpinelinux.org/alpine/v3.12/releases/x86_64/alpine-minirootfs-3.12.0-x86_64.tar.gz -o alpine.tgz
tar xzf alpine.tgz
rm -rf alpine.tgz

# Pull in kernel
curl -fL http://dl-cdn.alpinelinux.org/alpine/v3.12/releases/x86_64/alpine-netboot-3.12.0-x86_64.tar.gz -o netboot.tgz
tar xzf netboot.tgz boot/{config,initramfs,System.map,vmlinuz}-virt --no-same-owner
rm -rf netboot.tgz

# Save data for chroot
echo "FILE_POINTER=${FILE_POINTER}" > blocks
echo "BOOT=$(blkid ${FILE_POINTER}p1 --output export | grep --color=never '^UUID')" >> blocks
echo "ROOT=$(blkid ${FILE_POINTER}p2 --output export | grep --color=never '^UUID')" >> blocks

CHROOT_DIR=$PWD

chroot $CHROOT_DIR /bin/sh <<"EOF"

    source blocks
    echo $FILE_POINTER
    echo $BOOT
    echo $ROOT

    echo "$ROOT / ext4 rw,relatime 0 1" >> /etc/fstab
    echo "$BOOT /boot vfat rw,relatime 0 2" >> /etc/fstab

    # Install extra packages
    rm -r /var/cache/apk
    mkdir -p /var/cache/apk
    echo 'nameserver 1.1.1.1' > /etc/resolv.conf
    apk update
    apk add openrc openssh sudo syslinux

    # Configure users
    adduser -D --home /home/vagrant --shell /bin/sh vagrant
    sh -c "echo 'vagrant:vagrant' | chpasswd"
    echo 'vagrant ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant
    sh -c "echo 'root:vagrant' | chpasswd"

    # Configure SSH
    sed -i -E 's/^#?\s*UseDNS.*$/UseDNS no/' /etc/ssh/sshd_config
    mkdir -p /home/vagrant/.ssh
    wget https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant -o /home/vagrant/.ssh/vagrant
    wget https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/vagrant.pub
    cat /home/vagrant/.ssh/vagrant.pub > /home/vagrant/.ssh/authorized_keys
    chmod 0700 /home/vagrant/.ssh
    chmod 0600 /home/vagrant/.ssh/authorized_keys
    chmod 0600 /home/vagrant/.ssh/vagrant
    chmod 0644 /home/vagrant/.ssh/vagrant.pub
    chown -R vagrant:vagrant /home/vagrant

    # Configure syslinux
    # dd bs=440 count=1 conv=notrunc if=/usr/share/syslinux/gptmbr.bin of=${FILE_POINTER}
    sed -i -e 's/^default_kernel_opts.*$/default_kernel_opts="cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory"/' -e 's/^root=.*$/root='"$ROOT"'/' /etc/update-extlinux.conf
    update-extlinux

    # Tidy up
    ls -alh /
    rm -rf ./blocks ./vagrant{,.pub}

EOF

cd ..

# Unmount everything
umount mnt/{boot,dev,proc}
umount mnt
losetup -d $FILE_POINTER

virt-filesystems -a alpine.img --all --long --uuid -h

# kvm -m 2048 -drive file=alpine.img,format=raw,index=0,media=disk
