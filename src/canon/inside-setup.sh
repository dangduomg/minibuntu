rsync -a --chown=root:root "$src_dir/inside-setup" "$os_root"

machine_name=build-$(python3 "$src_root/gen-id.py")

systemd-run systemd-nspawn -b -D "$os_root" --machine="$machine_name"

until machinectl show "$machine_name" | grep -q "State=running"; do
    sleep 1
done

machinectl shell "$machine_name" /bin/bash /inside-setup/setup.sh

machinectl poweroff "$machine_name"
while machinectl list | grep -q  "$machine_name"; do
    sleep 1
done

rm -r "$os_root/inside-setup"