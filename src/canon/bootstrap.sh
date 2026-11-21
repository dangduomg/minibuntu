if [[ -d "$os_root" ]]; then
    rm -r "$os_root"
fi
mkdir -p "$os_root"

base_root=$build_root/base/root

if [[ ! -d "$base_root" ]]; then
    source "$src_root/base/build.sh"
fi

rsync -a --chown=root:root "$base_root/" "$os_root"