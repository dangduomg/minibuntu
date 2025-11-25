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

systemd-nspawn -D root --machine=minibuntu-canon --as-pid2 bash -c "
    echo 'Acquire::http::Proxy \"http://127.0.0.1:3142\";' \
        > /etc/apt/apt.conf.d/01proxy

    apt-get update
    
    # core
    apt-get install --no-install-recommends -y \
        linux-firmware \
        wpasupplicant \
        locales \
        plymouth plymouth-theme-ubuntu-gnome-logo \
        lightdm \
        xdg-user-dirs \
        pulseaudio \
        gvfs gvfs-fuse gvfs-backends \
        dosfstools mtools exfatprogs ntfs-3g
    
    # ui
    # i put xfce4-terminal here to override xorg's gnome-terminal default
    apt-get install --no-install-recommends -y \
        xorg xfce4 xfce4-notifyd tumbler xfce4-pulseaudio-plugin \
        xfce4-power-manager-plugins network-manager-gnome \
        lightdm-gtk-greeter light-locker

    # theme
    apt-get install -y \
        orchis-gtk-theme papirus-icon-theme bibata-cursor-theme fonts-ubuntu

    # system tools
    apt-get install --no-install-recommends -y \
        policykit-1-gnome \
        xfce4-taskmanager \
        synaptic \
        gdebi \
        gnome-software \
        gnome-software-plugin-flatpak \
        ubuntu-release-upgrader-gtk

    # utilities
    apt-get install --no-install-recommends -y \
        mate-calc \
        pluma \
        eom \
        parole \
        pavucontrol \
        xfce4-screenshooter \
        atril \
        engrampa \
        abiword \
        gnumeric

    # web browser
    apt-get install --no-install-recommends -y epiphany-browser

    # system tools (live only)
    apt-get install --no-install-recommends -y \
        usb-creator-gtk \
        gparted \
        hardinfo

    # autologin (live only)
    apt-get install --no-install-recommends -y lightdm-autologin-greeter

    # calamares installer (live only)
    apt-get install --no-install-recommends -y \
        rsync \
        busybox-syslogd \
        calamares
"

rsync -aHAX --numeric-ids --chown=root:root oem/after/ root/

systemd-nspawn -D root --machine=minibuntu-canon --as-pid2 bash -c "
    apt-get install --no-install-recommends -y -f /pkgs/*
    rm -r /pkgs
        
    apt-get clean
    
    rm /etc/apt/apt.conf.d/01proxy
"

systemd-nspawn -b -D root --machine=minibuntu-canon > /dev/null &

until machinectl show minibuntu-canon | grep -q "State=running"; do
    sleep 1
done
machinectl shell minibuntu-canon /bin/bash -c "
    flatpak remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
"
machinectl poweroff minibuntu-canon