#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
    echo 'run this script as root'
    exit 1
fi

if [[ ! -d ../root-base ]]; then
    source ../buildroot-base.sh
fi

if [[ -d root ]]; then
    rm -r root
fi
mkdir root

rsync -aHAX --numeric-ids --delete ../root-base/ root/

rsync -aHAX --numeric-ids --chown=root:root oem/before/ root/

systemd-nspawn -D root --machine=rescue bash -c "
    echo 'Acquire::http::Proxy \"http://127.0.0.1:3142\";' \
        > /etc/apt/apt.conf.d/01proxy

    apt-get update

    apt-get install --no-install-recommends -y \
        linux-modules-extra-6.8.0-31-generic \
        wpasupplicant \
        xorg \
        xfce4 \
        libasound2t64 \
        libdbus-glib-1-2 \
        policykit-1-gnome \
        gvfs \
        dosfstools \
        mtools \
        exfatprogs \
        ntfs-3g \
        thunar-volman \
        network-manager-gnome \
        tango-icon-theme \
        lxterminal \
        htop \
        mousepad \
        xarchiver \
        gparted \
        hardinfo \
        ghex \
        viewnior \
        xpdf \
        xsol \
        chntpw \
        clonezilla \
        nwipe \
        clamav \
        -f /pkgs/*

    rm -r /pkgs
        
    apt-get clean
    rm -r /var/lib/apt/lists/*
    
    rm /etc/apt/apt.conf.d/01proxy
"

rsync -aHAX --numeric-ids --chown=root:root oem/after/ root/
