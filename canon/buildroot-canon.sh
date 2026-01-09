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

systemd-nspawn -D root --machine=minibuntu-canon --as-pid2 bash -c "
    echo 'Acquire::http::Proxy \"http://127.0.0.1:3142\";' > /proxy
    cp /proxy /etc/apt/apt.conf.d/01proxy

    apt-get update
    
    # core
    apt-get install --no-install-recommends -y \
        linux-firmware \
        wpasupplicant \
        locales \
        plymouth plymouth-themes \
        lightdm \
        xdg-user-dirs \
        xdg-user-dirs-gtk \
        pulseaudio \
        gvfs gvfs-fuse gvfs-backends \
        dosfstools mtools exfatprogs ntfs-3g \
        python3-psutil \
        systemd-timesyncd \
        policykit-desktop-privileges

    # flatpak
    # no packages is installed by default for lightness
    apt-get install --no-install-recommends -y \
        flatpak \
        xdg-desktop-portal \
        xdg-desktop-portal-gtk
    
    # ui
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
        gnome-system-tools \
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