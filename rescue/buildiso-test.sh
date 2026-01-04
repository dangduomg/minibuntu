#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo 'run this script as root'
   exit 1
fi

image_name=minibuntu-rescue

root=$(realpath root)

iso_name="$image_name-$(date +%Y.%m.%d.%H.%M.%S).iso"

mkdir -p image/{.disk,casper,isolinux,install}

cp "$root/boot/vmlinuz-6.8.0-31-generic" image/casper/vmlinuz
cp "$root/boot/initrd.img-6.8.0-31-generic" image/casper/initrd

touch image/ubuntu


cat > image/isolinux/grub.cfg <<EOF

search --set=root --file /ubuntu

set default="0"
set timeout=0

menuentry "Run $image_name" {
   linux /casper/vmlinuz boot=casper quiet splash ---
   initrd /casper/initrd
}

EOF

cd image

cat > README.diskdefines <<EOF
#define DISKNAME  MINIBUNTU
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF

grub-mkstandalone \
    --format=i386-pc \
    --output=isolinux/core.img \
    --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
    --modules="linux16 linux normal iso9660 biosdisk search" \
    --locales="" \
    --fonts="" \
    boot/grub/grub.cfg=isolinux/grub.cfg

cat "$root/usr/lib/grub/i386-pc/cdboot.img" isolinux/core.img \
    > isolinux/bios.img

find . -type f -print0 | xargs -0 md5sum | grep -v -e 'isolinux' \
    > md5sum.txt

cd ..

cp -r "$root/image" .

mksquashfs "$root" image/casper/filesystem.squashfs \
   -noappend -no-duplicates -no-recovery \
   -wildcards \
   -no-compression \
   -e "image" \
   -e "var/cache/apt/archives/*" \
   -e "root/*" \
   -e "root/.*" \
   -e "tmp/*" \
   -e "tmp/.*" \
   -e "swapfile"

printf "$(sudo du -sx --block-size=1 "$root" | cut -f1)" \
    > image/casper/filesystem.size

cd image

sudo xorriso \
   -as mkisofs \
   -iso-level 3 \
   -full-iso9660-filenames \
   -J -J -joliet-long \
   -volid MINIBUNTU \
   -output "../$iso_name" \
   -eltorito-boot isolinux/bios.img \
     -no-emul-boot \
     -boot-load-size 4 \
     -boot-info-table \
     --eltorito-catalog boot.catalog \
     --grub2-boot-info \
     --grub2-mbr "$root/usr/lib/grub/i386-pc/boot_hybrid.img" \
     -partition_offset 16 \
     --mbr-force-bootable \
   -exclude isolinux \
   -graft-points \
      "/isolinux/bios.img=isolinux/bios.img" \
      "."

cd ..
rm -r image