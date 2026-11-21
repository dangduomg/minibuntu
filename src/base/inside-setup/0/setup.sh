debconf-set-selections "$this_setup_root/preseed.txt"

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install --no-install-recommends -y \
    systemd-sysv \
    linux-image-6.8.0-31-generic \
    linux-modules-extra-6.8.0-31-generic \
    grub-pc \
    grub-efi-amd64-signed \
    shim-signed \
    casper \
    zstd \
    gvfs gvfs-fuse gvfs-backends \
    dosfstools mtools exfatprogs ntfs-3g \
    network-manager \
    systemd-resolved \
    systemd-timesyncd \
    iputils-ping \
    wpasupplicant \
    console-setup \
    policykit-1 \
    bash-completion \
    sudo \
    nano \
    dialog