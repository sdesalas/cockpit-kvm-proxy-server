#! /bin/bash -ex

# Please run as `root` user 
# $ sudo setup.sh

apt update
apt install -y git htop

# Step 1: Setup KVM
# @see https://www.tecmint.com/install-kvm-on-ubuntu/
apt install -y cpu-checker
kvm-ok
apt install -y qemu qemu-kvm libvirt-daemon libvirt-clients bridge-utils virt-manager
systemctl status libvirtd
systemctl enable --now libvirtd
lsmod | grep -i kvm

# Step 2: Cockpit + virtual machines addon
apt install cockpit cockpit-machines
systemctl start cockpit

# Step 3: Caddy Reverse proxy
sudo ufw enable
sudo ufw allow 22/tcp 443/tcp 80/tcp 9090/tcp


