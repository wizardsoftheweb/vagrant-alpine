#!/bin/sh
#
# Copyright 2020 CJ Harries
# Licensed under http://www.apache.org/licenses/LICENSE-2.0

set -x

# shellcheck disable=SC1091
. blocks
echo "$ROOT"

echo "$ROOT / ext4 rw,relatime 0 1" >> /etc/fstab

# Install extra packages
echo 'nameserver 1.1.1.1' > /etc/resolv.conf
apk update --no-cache
apk add linux-virt syslinux openrc openssh sudo

# Configure users
adduser -D --home /home/vagrant --shell /bin/sh vagrant
echo "vagrant:vagrant" | chpasswd
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant
echo "root:vagrant" | chpasswd

# Configure SSH
sed -i -E 's/^#?\s*UseDNS.*$/UseDNS no/' /etc/ssh/sshd_config
mkdir -p /home/vagrant/.ssh
wget https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant     -O /home/vagrant/.ssh/vagrant
wget https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/vagrant.pub
cat /home/vagrant/.ssh/vagrant.pub > /home/vagrant/.ssh/authorized_keys
chmod 0700 /home/vagrant/.ssh
chmod 0600 /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/vagrant
chmod 0644 /home/vagrant/.ssh/vagrant.pub
chown -R vagrant:vagrant /home/vagrant

# Configure bootloader
sed -i -e 's/^default_kernel_opts.*$/default_kernel_opts="cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory"/' -e 's/^root=.*$/root='"$ROOT"'/' /etc/update-extlinux.conf
update-extlinux

# TODO: tidy
rm -rf /blocks /provision.sh
