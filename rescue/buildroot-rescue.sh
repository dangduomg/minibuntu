#!/bin/bash

set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    echo 'run this script as root'
    exit 1
fi

if [[ ! -d ../root-base ]]; then
    pushd ..
    source ./buildroot-base.sh
    popd
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

    # core
    apt-get install --no-install-recommends -y \
        libasound2t64 \
        libdbus-glib-1-2
    
    # ui
    apt-get install --no-install-recommends -y \
        xorg xfce4 lxterminal tango-icon-theme policykit-1-gnome \
        thunar-volman \
        network-manager-gnome \
    
    # utilities
    apt-get install --no-install-recommends -y \
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
        testdisk \
        baobab \
        gnome-disk-utility \
        xdemineur \
        -f /pkgs/*

    rm -r /pkgs
"

rsync -aHAX --numeric-ids --chown=root:root oem/after/ root/

systemd-nspawn -D root bash -c "
    apt-get install --no-install-recommends -y -f /pkgs/*
    rm -r /pkgs
        
    apt-get clean
    
    rm /etc/apt/apt.conf.d/01proxy
"
