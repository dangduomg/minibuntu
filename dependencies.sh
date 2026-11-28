#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
    echo 'run this script as root'
    exit 1
fi

set -euo pipefail

apt-get update
apt-get install --no-install-recommends -y \
    debootstrap \
    systemd-container \
    wget \
    unzip \
    rsync \
    squashfs-tools \
    dosfstools \
    mtools \
    xorriso \
    apt-cacher-ng