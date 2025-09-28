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
        --variant=minbase plucky bootstrap
fi

if [[ -d root-base ]]; then
    rm -r root-base
fi
mkdir root-base

debootstrap --unpack-tarball="$(realpath bootstrap.tar.gz)" \
    noble root-base
    
rsync -aHAX --numeric-ids --chown=root:root oem-base/before/ root-base/

systemd-nspawn -D root-base --machine=base /bin/bash -c "
    for pkg in \
        libxxhash0_0.8.3-2_amd64.deb \
        libstdc++6_15-20250404-0ubuntu1_amd64.deb \
        liblz4-1_1.10.0-4_amd64.deb \
        libapt-pkg7.0_3.0.0_amd64.deb \
        libseccomp2_2.5.5-1ubuntu6_amd64.deb \
        libgpg-error0_1.51-3_amd64.deb \
        libassuan9_3.0.2-2_amd64.deb \
        libgcrypt20_1.11.0-6ubuntu1_amd64.deb \
        libnpth0t64_1.8-2_amd64.deb \
        gpgv_2.4.4-2ubuntu23_amd64.deb \
        ubuntu-keyring_2023.11.28.1_all.deb \
        apt_3.0.0_amd64.deb \
    ; do
        dpkg -i \"/var/cache/apt/archives/\$pkg\"
    done

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
