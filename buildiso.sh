#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo 'run this script as root'
   exit 1
fi

set -euo pipefail

variant=$1

project_root=$(dirname "$(realpath "$0")")
src_dir=$project_root/src
build_dir=$project_root/build/$variant
image_dir=$build_dir/image
os_root=$build_dir/root

iso_name="minibuntu-$variant-$(date +%Y.%m.%d.%H.%M.%S).iso"


mkdir -p "$image_dir"/{.disk,casper,isolinux,install}

cp "$os_root/boot/vmlinuz-6.8.0-31-generic" "$image_dir/casper/vmlinuz"
cp "$os_root/boot/initrd.img-6.8.0-31-generic" "$image_dir/casper/initrd"

touch "$image_dir/ubuntu"


python3 "$src_dir/generate-grub.py" "$variant" > "$image_dir/isolinux/grub.cfg"

pushd "$image_dir"

cp "$os_root/usr/lib/shim/shimx64.efi.signed.previous" isolinux/bootx64.efi
cp "$os_root/usr/lib/shim/mmx64.efi" isolinux/mmx64.efi
cp "$os_root/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed" isolinux/grubx64.efi

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
    boot/grub/grub.cfg=isolinux/grub.cfg

cat "$os_root/usr/lib/grub/i386-pc/cdboot.img" isolinux/core.img \
    > isolinux/bios.img

find . -type f -print0 | xargs -0 md5sum | grep -v -e 'isolinux' \
    > md5sum.txt

popd

mksquashfs "$os_root" "$image_dir/casper/filesystem.squashfs" \
   -noappend -no-duplicates -no-recovery \
   -wildcards \
   -comp xz -b 1M -Xdict-size 100% \
   -e "image" \
   -e "root/*" \
   -e "root/.*" \
   -e "tmp/*" \
   -e "tmp/.*" \
   -e "swapfile"

printf "$(du -sx --block-size=1 "$os_root" | cut -f1)" \
    > "$image_dir/casper/filesystem.size"

pushd "$image_dir"

mkdir -p "$build_dir/isos"

xorriso \
   -as mkisofs \
   -iso-level 3 \
   -full-iso9660-filenames \
   -J -J -joliet-long \
   -volid UBNETINST \
   -output "$build_dir/isos/$iso_name" \
   -eltorito-boot isolinux/bios.img \
     -no-emul-boot \
     -boot-load-size 4 \
     -boot-info-table \
     --eltorito-catalog boot.catalog \
     --grub2-boot-info \
     --grub2-mbr "$os_root/usr/lib/grub/i386-pc/boot_hybrid.img" \
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

popd

rm -r "$image_dir"