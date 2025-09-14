#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
    echo 'run this script as root'
    exit 1
fi

if [[ ! -d root ]]; then
    source ./buildroot.sh
fi

false && mksquashfs root/ root/image/casper/filesystem.squashfs \
   -noappend -no-duplicates -no-recovery \
   -wildcards \
   -comp xz -b 1M -Xdict-size 100% \
   -e "var/cache/apt/archives/*" \
   -e "root/*" \
   -e "root/.*" \
   -e "tmp/*" \
   -e "tmp/.*" \
   -e "swapfile"

fallocate -l 2G root.img
rootloop=$(losetup -fP --show root.img)

mkfs.ext4 root.img
mkdir imgroot
mount "${rootloop}" imgroot

rsync -aHAX --numeric-ids root/ imgroot/

cd imgroot
mv image cdrom

systemd-nspawn bash -c "
    useradd -m -s /bin/bash -G sudo,users ubuntu
    passwd -du ubuntu
    
    touch /var/log/casper.log
"

cd ..
umount imgroot
rmdir imgroot

if [[ ! -f target.qcow2 ]]; then
    qemu-img create -f qcow2 target.qcow2 10G
fi

qemu-system-x86_64 -enable-kvm -m 2G -kernel root/boot/vmlinuz \
    -initrd root/boot/initrd.img -append 'root=/dev/sda rw' \
    -hda root.img -hdb target.qcow2

rm root.img
losetup -d "$rootloop"
