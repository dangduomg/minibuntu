#!/bin/bash

if [[ ! -f target.qcow2 ]]; then
    qemu-img create -f qcow2 target.qcow2 10G
fi

qemu-system-x86_64 -enable-kvm -m 2G -hda target.qcow2
