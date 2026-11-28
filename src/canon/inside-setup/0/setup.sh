phase_root=$(dirname "$(realpath "$0")")

export DEBIAN_FRONTEND=noninteractive

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
# no packages are installed by default for lightness
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

# browser
apt-get install --no-install-recommends -y firefox

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

# boot-repair (live only)
apt-get install --no-install-recommends -y libnotify-dev boot-repair

# mate-admin-tools-4all
dpkg-deb -b --root-owner-group "$phase_root/mate-admin-tools-4all/" \
    "$phase_root/mate-admin-tools-4all.deb"
apt-get install --no-install-recommends -y \
    "$phase_root/mate-admin-tools-4all.deb"