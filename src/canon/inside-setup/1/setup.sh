phase_root=$(dirname "$(realpath "$0")")

# come back to internal repo
cp /proxy /etc/apt/apt.conf.d/01proxy

# calamares settings
dpkg-deb -b --root-owner-group "$phase_root/calamares-settings/" \
    "$phase_root/calamares-settings.deb"
apt-get install --no-install-recommends -y \
    "$phase_root/calamares-settings.deb"

apt-get clean

rm /proxy /etc/apt/apt.conf.d/01proxy