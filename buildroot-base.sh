#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
    echo 'run this script as root'
    exit 1
fi

if [[ -d root-base ]]; then
    rm -r root-base
fi
mkdir root-base

debootstrap --arch=amd64 --variant=minbase noble root-base

rsync -aHAX --numeric-ids --chown=root:root oem-base/before/ root-base/

systemd-nspawn -D root-base --machine=base /bin/bash -c "
    echo 'Acquire::http::Proxy \"http://127.0.0.1:3142\";' \
        > /etc/apt/apt.conf.d/01proxy

    apt-get update

    debconf-set-selections /preseed.txt

    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        systemd-sysv \
        linux-image-6.8.0-31-generic \
        linux-modules-extra-6.8.0-31-generic \
        grub-pc \
        grub-efi-amd64-signed \
        shim-signed \
        casper \
        zstd \
        gvfs gvfs-fuse gvfs-backends \
        dosfstools mtools exfatprogs ntfs-3g \
        network-manager \
        systemd-resolved \
        systemd-timesyncd \
        iputils-ping \
        wpasupplicant \
        console-setup \
        policykit-1 \
        bash-completion \
        sudo \
        nano \
        dialog

    apt-get clean
    rm -r /var/lib/apt/lists/*
    
    rm /etc/apt/apt.conf.d/01proxy
    rm /preseed.txt
"

rsync -aHAX --numeric-ids --chown=root:root oem-base/after/ root-base/
