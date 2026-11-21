export DEBIAN_FRONTEND=noninteractive
apt-get upgrade -y
apt-get clean

rm -r /var/lib/apt/lists/*
rm /etc/apt/apt.conf.d/01proxy