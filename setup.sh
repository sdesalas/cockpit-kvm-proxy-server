#! /bin/bash -ex

export EXTERNAL_SITE_ADDRESS=hpserver1.crafty.monster
export DDNS_PASSWORD=7b2af01dca8bed

# Please run as `root` user 
# $ sudo setup.sh

echo "Step 0: Install common tools" && sleep 3
apt update
apt install -y git curl htop nano gettext-base apt-transport-https 

echo "Step 1: Setup KVM" && sleep 3
# @see https://www.tecmint.com/install-kvm-on-ubuntu/
apt install -y cpu-checker
kvm-ok
apt install -y qemu qemu-kvm libvirt-daemon libvirt-clients bridge-utils virt-manager
sleep 5
systemctl status --no-pager libvirtd
systemctl enable --now libvirtd
lsmod | grep -i kvm

echo "Step 2: Cockpit + virtual machines addon"  && sleep 3
apt install -y cockpit cockpit-machines
envsubst < ./cockpit.conf > /etc/cockpit/cockpit.conf
systemctl restart cockpit
sleep 5
systemctl enable --now cockpit
systemctl status --no-pager cockpit

echo "Step 3: Install Caddy" && sleep 3
apt install -y debian-keyring debian-archive-keyring
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor --always-trust --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy
systemctl enable --now caddy

echo "Step 4: Configure caddy" && sleep 3
ufw enable
ufw allow 22,443,80/tcp
echo "EXTERNAL_SITE_ADDRESS=$EXTERNAL_SITE_ADDRESS" >> /etc/environment
cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bkp
cp ./Caddyfile /etc/caddy/
systemctl restart caddy
sleep 5
systemctl status --no-pager caddy

echo "Step 5: Configure DDNS using cronjob" && sleep 3
if [[ ! -z "$DDNS_PASSWORD" ]]; then
  EXTERNAL_SUBDOMAIN=$(echo $EXTERNAL_SITE_ADDRESS | cut -d '.' -f 1)
  EXTERNAL_DOMAIN=${"$EXTERNAL_SITE_ADDRESS"/"$EXTERNAL_SUBDOMAIN."/""}
  cp ./ddns.sh /root/
  (crontab -l 2>/dev/null; echo "15 */4 * * * /root/ddns.sh $EXTERNAL_SUBDOMAIN $EXTERNAL_DOMAIN $DDNS_PASSWORD >> /root/ddns.log") | crontab -
else 
  echo "No DDNS_PASSWORD, skipping..."
fi
