#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo 'This script should be run as root.'
    exit 1
fi

set -euo pipefail

variant=$1

project_root=$(dirname "$(realpath "$0")")
src_root=$project_root/src
src_dir=$src_root/$variant
build_dir=$project_root/build/$variant
os_root=$build_dir/root
overlay_dir=$build_dir/overlay
merged_root=$overlay_dir/merged

machine_tag=$(python3 "$src_root/gen-id.py")

# create overlay filesystem
if ! findmnt "$merged_root"; then
    mount -t overlay "overlay-$machine_tag" \
        -o "lowerdir=$os_root" \
        -o "upperdir=$overlay_dir/upper" \
        -o "workdir=$overlay_dir/work" \
        "$merged_root"
fi

systemd-nspawn -D "$merged_root" \
    --machine="run-$(python3 "$src_root/gen-id.py")" \
    --as-pid2 /bin/bash -c "
        if ! grep -q '^user:' /etc/passwd; then
            useradd -m -s /bin/bash user
            usermod -aG sudo user
            passwd -d user
            echo 'User "user" is now created with no password and sudo rights'
        fi
    "

systemd-run systemd-nspawn -b -D "$merged_root" --machine="run-$machine_tag"

echo "The virtual container is now running with machine name run-$machine_tag"