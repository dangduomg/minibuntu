#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
    echo 'run this script as root'
    exit 1
fi

if [[ ! -d root ]]; then
    source ./buildroot.sh
fi

source ./buildiso-test.sh

qemu-system-x86_64 -enable-kvm -m 2G -cdrom "$iso_name"

rm "$iso_name"