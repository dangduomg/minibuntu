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

systemd-nspawn -D root --machine=calatest bash -c "
    echo 'Acquire::http::Proxy \"http://127.0.0.1:3142\";' \
        > /etc/apt/apt.conf.d/01proxy

    apt-get update
    
    apt-get install --no-install-recommends -y \
        locales \
        squashfs-tools \
        busybox-syslogd \
        rsync \
        xserver-xorg \
        xserver-xorg-video-fbdev \
        xserver-xorg-input-libinput \
        lightdm \
        lightdm-autologin-greeter \
        lightdm-gtk-greeter \
        openbox \
        calamares \
        xterm
"

rsync -aHAX --numeric-ids --chown=root:root oem/after/ root/

systemd-nspawn -D root bash -c "
    apt-get install --no-install-recommends -y -f /pkgs/*
    rm -r /pkgs
        
    apt-get clean
    
    rm /etc/apt/apt.conf.d/01proxy
"
