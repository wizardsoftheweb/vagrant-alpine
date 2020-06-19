#!/bin/bash
#
# Copyright 2020 CJ Harries
# Licensed under http://www.apache.org/licenses/LICENSE-2.0

VM_NAME=alpine-test

rm -rf alpine.vmdk

VBoxManage convertfromraw --format VMDK alpine.img alpine.vmdk

VBoxManage createvm \
    --name "${VM_NAME}" \
    --ostype "Other Linux (64-bit)" \
    --register

CONFIG_DIR=$(
    VBoxManage showvminfo "${VM_NAME}" --machinereadable \
        | sed -n -E 's/^CfgFile="([^"]*)"$/\1/p' \
        | xargs -d '\n' -n 1 dirname
)

mv alpine.vmdk "${CONFIG_DIR}/alpine.vmdk"

VBoxManage storagectl "${VM_NAME}" \
    --name AHCI \
    --add sata \
    --controller IntelAHCI \
    --bootable on

VBoxManage storageattach "${VM_NAME}" \
    --storagectl AHCI \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "${CONFIG_DIR}/alpine.vmdk"
