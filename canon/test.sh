#!/bin/bash

set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    echo 'run this script as root'
    exit 1
fi

if [[ ! -d root ]]; then
    source ./buildroot.sh
fi

source ./buildiso-test.sh

if [[ -f target.qcow2 ]]; then
    rm target.qcow2
fi
qemu-img create -f qcow2 target.qcow2 10G

qemu-system-x86_64 -enable-kvm -m 2G -hda target.qcow2 -cdrom "$iso_name"

rm "$iso_name"