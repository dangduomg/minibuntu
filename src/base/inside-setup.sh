rsync -a --chown=root:root "$src_dir/inside-setup" "$os_root"

systemd-nspawn -D "$os_root" \
    --machine="build-$(python3 "$src_root/gen-id.py")" \
    --as-pid2 /inside-setup/setup.sh

rm -r "$os_root/inside-setup"