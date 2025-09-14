#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo 'run this script as root'
   exit 1
fi

if [[ -z "$1" ]]; then
    read -p 'choose root directory: ' root_input
else
    root_input=$1
fi

if [[ -z "$2" ]]; then
    read -p 'name your image: ' image_name
else
    image_name=$2
fi

root=$(realpath $root_input)

mkdir -p image/{.disk,casper,isolinux,install}

cp "$root/boot/vmlinuz-6.8.0-31-generic" image/casper/vmlinuz
cp "$root/boot/initrd.img-6.8.0-31-generic" image/casper/initrd

wget --progress=dot -O image/memtest.zip \
    https://www.memtest.org/download/v7.20/mt86plus_7.20.binaries.zip
unzip -p image/memtest.zip memtest64.bin > image/install/memtest86+.bin
unzip -p image/memtest.zip memtest64.efi > image/install/memtest86+.efi
rm image/memtest.zip

touch image/ubuntu


cat > image/isolinux/grub.cfg <<EOF

search --set=root --file /ubuntu

insmod all_video

set default="0"
set timeout=30

menuentry "Run $image_name" {
   linux /casper/vmlinuz boot=casper ---
   initrd /casper/initrd
}

menuentry "Check disc for defects" {
   linux /casper/vmlinuz boot=casper integrity-check ---
   initrd /casper/initrd
}

grub_platform
if [ "\$grub_platform" = "efi" ]; then
menuentry 'UEFI Firmware Settings' {
   fwsetup
}

menuentry "Test memory Memtest86+ (UEFI)" {
   linux /install/memtest86+.efi
}
else
menuentry "Test memory Memtest86+ (BIOS)" {
   linux16 /install/memtest86+.bin
}
fi

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

cp "$root/usr/lib/shim/shimx64.efi.signed.previous" isolinux/bootx64.efi
cp "$root/usr/lib/shim/mmx64.efi" isolinux/mmx64.efi
cp "$root/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed" \
    isolinux/grubx64.efi

(
    cd isolinux && \
    dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
    mkfs.vfat -F 16 efiboot.img && \
    LC_CTYPE=C mmd -i efiboot.img efi efi/ubuntu efi/boot && \
    LC_CTYPE=C mcopy -i efiboot.img ./bootx64.efi ::efi/boot/bootx64.efi && \
    LC_CTYPE=C mcopy -i efiboot.img ./mmx64.efi ::efi/boot/mmx64.efi && \
    LC_CTYPE=C mcopy -i efiboot.img ./grubx64.efi ::efi/boot/grubx64.efi && \
    LC_CTYPE=C mcopy -i efiboot.img ./grub.cfg ::efi/ubuntu/grub.cfg
)

grub-mkstandalone \
    --format=i386-pc \
    --output=isolinux/core.img \
    --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
    --modules="linux16 linux normal iso9660 biosdisk search" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=isolinux/grub.cfg"

cat "$root/usr/lib/grub/i386-pc/cdboot.img" isolinux/core.img \
    > isolinux/bios.img

find . -type f -print0 | xargs -0 md5sum | grep -v -e 'isolinux' \
    > md5sum.txt

cd ..

cp -r "$root"/image .

mksquashfs "$root" image/casper/filesystem.squashfs \
   -noappend -no-duplicates -no-recovery \
   -wildcards \
   -comp xz -b 1M -Xdict-size 100% \
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
   -output "../$image_name-$(date +%Y.%m.%d.%H.%M.%S).iso" \
   -eltorito-boot isolinux/bios.img \
     -no-emul-boot \
     -boot-load-size 4 \
     -boot-info-table \
     --eltorito-catalog boot.catalog \
     --grub2-boot-info \
     --grub2-mbr "$root/usr/lib/grub/i386-pc/boot_hybrid.img" \
     -partition_offset 16 \
     --mbr-force-bootable \
   -eltorito-alt-boot \
     -no-emul-boot \
     -e isolinux/efiboot.img \
     -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b isolinux/efiboot.img \
     -appended_part_as_gpt \
     -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
     -m "isolinux/efiboot.img" \
     -m "isolinux/bios.img" \
     -e '--interval:appended_partition_2:::' \
   -exclude isolinux \
   -graft-points \
      "/EFI/boot/bootx64.efi=isolinux/bootx64.efi" \
      "/EFI/boot/mmx64.efi=isolinux/mmx64.efi" \
      "/EFI/boot/grubx64.efi=isolinux/grubx64.efi" \
      "/EFI/ubuntu/grub.cfg=isolinux/grub.cfg" \
      "/isolinux/bios.img=isolinux/bios.img" \
      "/isolinux/efiboot.img=isolinux/efiboot.img" \
      "."

cd ..
rm -r image
