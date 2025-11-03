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
    export http_proxy=http://127.0.0.1:3142
    debootstrap --foreign --arch=amd64 --variant=minbase plucky bootstrap
    chroot bootstrap /debootstrap/debootstrap --second-stage
    tar -czf bootstrap.tar.gz -C bootstrap .
    rm -r bootstrap
fi

if [[ -d root-base ]]; then
    rm -r root-base
fi
mkdir root-base

debootstrap --unpack-tarball="$(realpath bootstrap.tar.gz)" \
    plucky root-base
    
rsync -aHAX --numeric-ids --chown=root:root oem-base/before/ root-base/

systemd-nspawn -D root-base --machine=base /bin/bash -c "
    echo 'Acquire::http::Proxy \"http://127.0.0.1:3142\";' \
        > /etc/apt/apt.conf.d/01proxy

    apt-get update

    apt-get install --no-install-recommends -y dialog

    apt-get install --no-install-recommends -y \
        systemd-sysv \
        linux-image-6.14.0-15-generic \
        grub-pc \
        grub-efi-amd64-signed \
        shim-signed \
        casper \
        zstd \
        bash-completion \
        network-manager \
        systemd-resolved \
        iputils-ping \
        console-setup \
        polkitd \
        sudo \
        nano

    apt-get clean
    rm -r /var/lib/apt/lists/*
    
    rm /etc/apt/apt.conf.d/01proxy
"

rsync -aHAX --numeric-ids --chown=root:root oem-base/after/ root-base/
