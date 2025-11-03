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

systemd-nspawn -D root --machine=minibuntu-canon bash -c "
    echo 'Acquire::http::Proxy \"http://127.0.0.1:3142\";' \
        > /etc/apt/apt.conf.d/01proxy

    apt-get update
    
    # core
    apt-get install --no-install-recommends -y \
        plymouth plymouth-theme-ubuntu-gnome-logo \
        lightdm \
        xdg-user-dirs \
        pulseaudio \
        gvfs gvfs-fuse gvfs-backends

    # autologin
    apt-get install --no-install-recommends -y lightdm-autologin-greeter
    
    # ui
    # i put xfce4-terminal here to override xorg's gnome-terminal default
    apt-get install --no-install-recommends -y \
        xorg xfce4 xfce4-terminal xfce4-notifyd xfce4-pulseaudio-plugin \
        xfce4-power-manager-plugins network-manager-gnome xscreensaver

    # theme
    apt-get install -y \
        orchis-gtk-theme papirus-icon-theme bibata-cursor-theme fonts-ubuntu

    # system tools
    apt-get install --no-install-recommends -y \
        policykit-1-gnome \
        xfce4-taskmanager \
        dconf-editor \
        synaptic \
        gdebi \
        gnome-software \
        gnome-software-plugin-flatpak \
        ubuntu-release-upgrader-gtk
    
    # utilities
    apt-get install --no-install-recommends -y \
        galculator \
        pluma \
        eom \
        parole \
        pavucontrol \
        atril \
        abiword \
        gnumeric

    # web browser
    apt-get install --no-install-recommends -y epiphany-browser

    # snap
    apt-get install --no-install-recommends -y gnome-software-plugin-snap
"

rsync -aHAX --numeric-ids --chown=root:root oem/after/ root/

systemd-nspawn -D root bash -c "
    apt-get install --no-install-recommends -y -f /pkgs/*
    rm -r /pkgs
        
    apt-get clean
    
    rm /etc/apt/apt.conf.d/01proxy
"
