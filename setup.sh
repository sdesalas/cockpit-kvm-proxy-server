#! /bin/bash -ex

# Please run as `root` user 
# $ sudo setup.sh

apt update
apt install -y git htop debian-keyring debian-archive-keyring apt-transport-https

# Step 1: Setup KVM
# @see https://www.tecmint.com/install-kvm-on-ubuntu/
apt install -y cpu-checker
kvm-ok
apt install -y qemu qemu-kvm libvirt-daemon libvirt-clients bridge-utils virt-manager
sleep 5
systemctl status libvirtd
systemctl enable --now libvirtd
lsmod | grep -i kvm

# Step 2: Cockpit + virtual machines addon
apt install cockpit cockpit-machines
systemctl start cockpit
systemctl enable --now cockpit
sleep 5
systemctl status cockpit

# Step 3: Caddy Reverse proxy
ufw enable
ufw allow 22/tcp 443/tcp 80/tcp 9090/tcp
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy
systemctl enable --now caddy
cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bkp
cp ./Caddyfile /etc/caddy/
systemctl restart caddy
sleep 5
systemctl status caddy

