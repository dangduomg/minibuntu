import sys

variant = sys.argv[1]

print(f"""\
search --set=root --file /ubuntu

insmod all_video

set default="0"
set timeout=30

menuentry "Run minibuntu-{variant}" {{
    linux /casper/vmlinuz boot=casper verbose splash ---
    initrd /casper/initrd
}}

menuentry "Run minibuntu-{variant} (safe graphics)" {{
    linux /casper/vmlinuz boot=casper verbose nomodeset ---
    initrd /casper/initrd
}}

menuentry "Check disc for defects" {{
    linux /casper/vmlinuz boot=casper integrity-check ---
    initrd /casper/initrd
}}

grub_platform
if [ "$grub_platform" = "efi" ]; then
menuentry 'UEFI Firmware Settings' {{
    fwsetup
}}

menuentry "Test memory Memtest86+ (UEFI)" {{
    linux /install/memtest86+.efi
}}
else
menuentry "Test memory Memtest86+ (BIOS)" {{
    linux16 /install/memtest86+.bin
}}
fi
""")