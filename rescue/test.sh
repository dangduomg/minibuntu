#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
    echo 'run this script as root'
    exit 1
fi

if [[ ! -d root ]]; then
    source ./buildroot.sh
fi

fallocate -l 2G root.img
rootloop=$(losetup -fP --show root.img)

mkfs.ext4 root.img
mkdir imgroot
mount "${rootloop}" imgroot

rsync -aHAX --numeric-ids root/ imgroot/

cd imgroot

systemd-nspawn bash -c "
    useradd -m -s /bin/bash -G sudo,users ubuntu
    passwd -du ubuntu
"

cd ..
umount imgroot
rmdir imgroot

qemu-system-x86_64 -enable-kvm -cpu host -m 2G \
    -kernel root/boot/vmlinuz \
    -initrd root/boot/initrd.img -append 'root=/dev/sda rw' \
    -hda root.img

rm root.img
losetup -d "$rootloop"
