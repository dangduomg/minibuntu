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

systemd-nspawn -D root --machine=minibuntu-rescue --as-pid2 bash -c "
    echo 'Acquire::http::Proxy \"http://127.0.0.1:3142\";' > /proxy
    cp /proxy /etc/apt/apt.conf.d/01proxy

    apt-get update
    
    # core
    apt-get install --no-install-recommends -y \
        software-properties-common \
        lightdm-autologin-greeter \
        libasound2t64 \
        libdbus-glib-1-2

    # ui
    apt-get install --no-install-recommends -y \
        xorg icewm xfce4-terminal xfce4-appfinder

    # system tools
    apt-get install --no-install-recommends -y \
        pcmanfm \
        network-manager-gnome \
        policykit-1-gnome
    
    # recovery tools
    apt-get install --no-install-recommends -y \
        gparted \
        hardinfo \
        chntpw \
        clonezilla \
        nwipe \
        clamtk \
        testdisk \
        gnome-disk-utility \
        usb-creator-gtk \
        timeshift

    # utilities
    apt-get install --no-install-recommends -y \
        htop \
        mousepad \
        xarchiver \
        ghex \
        viewnior \
        xpdf \
        galculator \
        abiword

    # games :)
    apt-get install --no-install-recommends -y \
        xsol xdemineur
"

systemd-nspawn -b -D root --machine=minibuntu-rescue --bind=/etc/resolv.conf:/etc/resolv.conf > /dev/null &

until machinectl show minibuntu-rescue | grep -q "State=running"; do
    sleep 1
done
machinectl shell minibuntu-rescue /bin/bash -c "
    # external repo
    rm /etc/apt/apt.conf.d/01proxy
    add-apt-repository -y ppa:yannubuntu/boot-repair

    apt-get update

    # system tools (live only)
    apt-get install --no-install-recommends -y libnotify-dev boot-repair
"
machinectl poweroff minibuntu-rescue
while machinectl list | grep -q minibuntu-rescue; do
    sleep 1
done

rsync -aHAX --numeric-ids --chown=root:root oem/after/ root/

systemd-nspawn -D root --machine=minibuntu-rescue --as-pid2 bash -c "
    # come back to internal repo
    cp /proxy /etc/apt/apt.conf.d/01proxy
    apt-get install --no-install-recommends -y -f /pkgs/*
    rm -r /pkgs

    apt-get clean
    
    rm /proxy /etc/apt/apt.conf.d/01proxy
"