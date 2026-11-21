this_setup_root=$(dirname "$(realpath "$0")")

cp -ar "$this_setup_root/before"/* /

export DEBIAN_FRONTEND=noninteractive
apt-get upgrade -y
apt-get clean

rm -r /var/lib/apt/lists/*
rm /etc/apt/apt.conf.d/01proxy