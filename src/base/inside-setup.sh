rsync -a --chown=root:root "$src_dir/inside-setup" "$os_root"

systemd-nspawn -D "$os_root" --as-pid2 /inside-setup/setup.sh

rm -r "$os_root/inside-setup"