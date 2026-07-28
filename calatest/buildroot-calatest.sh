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

systemd-nspawn -D root --machine=calatest bash -c "
    echo 'Acquire::http::Proxy \"http://127.0.0.1:3142\";' > /proxy
    cp /proxy /etc/apt/apt.conf.d/01proxy

    apt-get update
    
    apt-get install --no-install-recommends -y \
        software-properties-common \
        python3-xdg \
        locales \
        squashfs-tools \
        busybox-syslogd \
        rsync \
        xserver-xorg \
        xserver-xorg-video-fbdev \
        xserver-xorg-input-libinput \
        lightdm \
        lightdm-gtk-greeter \
        openbox \
        fonts-ubuntu \
        calamares \
        xterm
"

# extra packages to ensure post-install removal is smooth (depends on calamares config)
# external packages are required
systemd-nspawn -D root --machine=calatest bash -c "
    apt-get install --no-install-recommends -y \
        lightdm-autologin-greeter \
        usb-creator-gtk \
        gparted \
        hardinfo \
        libnotify-dev \
        qt5ct \
        qt5-style-kvantum \
        orchis-kde \
        gnome-disk-utility
"
systemd-nspawn -b -D root --machine=minibuntu-calatest --bind=/etc/resolv.conf:/etc/resolv.conf > /dev/null &
until machinectl show minibuntu-calatest | grep -q "State=running"; do
    sleep 1
done
machinectl shell minibuntu-calatest /bin/bash -c "
    # external repo
    rm /etc/apt/apt.conf.d/01proxy
    add-apt-repository -y ppa:yannubuntu/boot-repair

    apt-get update
    apt-get install --no-install-recommends -y boot-repair
"
machinectl poweroff minibuntu-calatest
while machinectl list | grep -q minibuntu-calatest; do
    sleep 1
done

rsync -aHAX --numeric-ids --chown=root:root oem/after/ root/

systemd-nspawn -D root bash -c "
    # come back to internal repo
    cp /proxy /etc/apt/apt.conf.d/01proxy
    apt-get install --no-install-recommends -y -f /pkgs/*
    rm -r /pkgs
        
    apt-get clean

    rm /proxy /etc/apt/apt.conf.d/01proxy
"
