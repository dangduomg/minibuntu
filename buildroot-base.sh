#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
    echo 'run this script as root'
    exit 1
fi

if [[ ! -f bootstrap.tar.gz ]]; then
    if [[ -d bootstrap ]]; then
        rm -r bootstrap
    fi
    mkdir bootstrap
    debootstrap --make-tarball=bootstrap.tar.gz --arch=amd64 \
        --variant=minbase noble bootstrap
fi

if [[ -d root-base ]]; then
    rm -r root-base
fi
mkdir root-base

debootstrap --unpack-tarball="$(realpath bootstrap.tar.gz)" \
    noble root-base
    
rsync -aHAX --numeric-ids --chown=root:root oem-base/before/ root-base/

systemd-nspawn -D root-base --machine=base /bin/bash -c "
    echo 'Acquire::http::Proxy \"http://127.0.0.1:3142\";' \
        > /etc/apt/apt.conf.d/01proxy

    apt-get update

    apt-get install --no-install-recommends -y \
        systemd-sysv \
        linux-image-6.8.0-31-generic \
        grub-pc \
        grub-efi-amd64-signed \
        shim-signed \
        casper \
        zstd \
        dialog \
        bash-completion \
        network-manager \
        systemd-resolved \
        iputils-ping \
        console-setup \
        policykit-1 \
        sudo \
        nano

    apt-get clean
    rm -r /var/lib/apt/lists/*
    
    rm /etc/apt/apt.conf.d/01proxy
"

rsync -aHAX --numeric-ids --chown=root:root oem-base/after/ root-base/
