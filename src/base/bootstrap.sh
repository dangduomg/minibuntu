if [[ -d "$os_root" ]]; then
    rm -r "$os_root"
fi
mkdir -p "$os_root"

if [[ ! -f "$build_dir/root.tar.gz" ]]; then
    debootstrap --arch=amd64 --variant=minbase --make-tarball="$build_dir/root.tar.gz" noble "$os_root"
fi

debootstrap --unpack-tarball="$build_dir/root.tar.gz" noble "$os_root"