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

systemd-nspawn -D root --machine=minibuntu-canon --as-pid2 bash -c "
    echo 'Acquire::http::Proxy \"http://127.0.0.1:3142\";' > /proxy
    cp /proxy /etc/apt/apt.conf.d/01proxy

    apt-get update
    
    # core
    apt-get install --no-install-recommends -y \
        linux-generic \
        locales \
        plymouth plymouth-themes \
        lightdm \
        xdg-user-dirs \
        xdg-user-dirs-gtk \
        pulseaudio \
        python3-psutil \
        policykit-desktop-privileges

    # flatpak
    # no packages is installed by default for lightness
    apt-get install --no-install-recommends -y \
        flatpak \
        xdg-desktop-portal \
        xdg-desktop-portal-gtk
    
    # ui
    apt-get install --no-install-recommends -y \
        xorg xfce4 xfce4-notifyd tumbler xfce4-whiskermenu-plugin \
        xfce4-pulseaudio-plugin xfce4-power-manager-plugins \
        lightdm-gtk-greeter light-locker

    # theme
    apt-get install -y \
        orchis-gtk-theme papirus-icon-theme bibata-cursor-theme fonts-ubuntu \
        fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji

    # system tools
    apt-get install --no-install-recommends -y \
        network-manager-gnome \
        policykit-1-gnome \
        xfce4-taskmanager \
        synaptic \
        gnome-software \
        gnome-software-plugin-flatpak \
        ubuntu-release-upgrader-gtk \
        language-selector-gnome \
        blueman \
        thunar-volman \
        timeshift

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
        gnumeric \
        transmission-gtk \
        thunar-archive-plugin \
        menulibre \
        mugshot

    # system tools (live only)
    apt-get install --no-install-recommends -y \
        usb-creator-gtk \
        gnome-disk-utility \
        gparted \
        hardinfo

    # autologin (live only)
    apt-get install --no-install-recommends -y lightdm-autologin-greeter

    # calamares installer and qt themes (live only)
    apt-get install --no-install-recommends -y \
        rsync \
        busybox-syslogd \
        qt5ct qt5-style-kvantum orchis-kde \
        calamares
"

systemd-nspawn -b -D root --machine=minibuntu-canon > /dev/null &

until machinectl show minibuntu-canon | grep -q "State=running"; do
    sleep 1
done
machinectl shell minibuntu-canon /bin/bash -c "
    # external repo
    rm /etc/apt/apt.conf.d/01proxy
    gpg -n -q --import --import-options import-show \
        /etc/apt/keyrings/packages.mozilla.org.asc

    sudo add-apt-repository -y ppa:yannubuntu/boot-repair

    apt-get update

    # system tools (live only)
    apt-get install --no-install-recommends -y libnotify-dev boot-repair

    # browser
    apt-get install --no-install-recommends -y firefox

    flatpak remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
"
machinectl poweroff minibuntu-canon
while machinectl list | grep -q minibuntu-canon; do
    sleep 1
done

rsync -aHAX --numeric-ids --chown=root:root oem/after/ root/

systemd-nspawn -D root --machine=minibuntu-canon --as-pid2 bash -c "
    # come back to internal repo
    cp /proxy /etc/apt/apt.conf.d/01proxy
    apt-get install --no-install-recommends -y -f /pkgs/*
    rm -r /pkgs

    apt-get clean
    
    rm /proxy /etc/apt/apt.conf.d/01proxy
"