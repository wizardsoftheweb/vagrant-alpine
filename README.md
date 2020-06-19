# `vagrant-alpine`

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/) [![Check the NOTICE](https://img.shields.io/badge/Check%20the-NOTICE-420C3B.svg)](./NOTICE)

## Overview

I wanted to build a slimmer Alpine image for use with Vagrant while learning some new tooling. I learned some new tooling but I wasn't able to build the Vagrant images.

## Prequisites

I didn't track system deps, so you'll potentially have to hunt them down.

* Vagrant
* Virtual Box
* `libvirt` + `qemu`
* `libguestfs`
* `{s,}fdisk`
* `chroot` and `losetup` should be ubiquituous

## Usage

### `compile.sh`

This is the primary script.

1. Creates, partitions, and formats a `raw` QEMU image
2. Creates a `chroot`
   1. Installs alpine's `minirootfs`
   2. Installs necessary chunks from alpine's `netboot` as `minirootfs` does not have a kernel
   3. Sets up Vagrant users
   4. Installs and configures `openssh` for Vagrant use
   5. Attempts to properly configure `syslinux`
3. Displays info about run
4. Provides `kvm` test shortcut

It generates `alpine.im`, a `raw` QEMU image that is. unfortunately, not actually bootable.

### `generate-virtualbox.sh`

1. Converts `alpine.img` to `alpine.vmdk`
2. Creates a new VM
3. Sets up storage access
4. Assigns `alpine.vdmk`

As `alpine.img` is not bootable, neither is the created VBox.

### `unmount-all.sh`

Convenience script to unmount all the things I normally had mounted while developing `compile.sh`.

## Failure

No matter what, I was unable to get the image to boot. At a glance, it looks like it should work. I tried both MBR and GPT (with preformatting for `sfdisk` in `mbr.out` and `gpt.out`, respectively). I tried a slew of configurations.

* Is the loop device the problem?
* Is the `chroot` the problem?
* Is the bootloader the problem?
* Is the fs the problem?
* Is the kernel the problem?
* Is the operator the problem?

If you have any insight, I'd love to hear from you! PRs, comments, and issues are very welcome.
