#!/bin/sh
# Roll your own Namecheap DDNS
# Shell script to update namecheap.com dynamic dns
# for a domain to your external IP address
#
# Usage: 
# $ ddns.sh webmail mydomain.com 7b2af01dca8bed

SUBDOMAIN=${1:-"$DDNS_SUBDOMAIN"}
DOMAIN=${2:-"$DDNS_DOMAIN"}
PASSWORD=${3:-"$DDNS_PASSWORD"}

IP=`curl -s ipecho.net/plain`

URL="https://dynamicdns.park-your-domain.com/update?host=$SUBDOMAIN&domain=$DOMAIN&password=$PASSWORD&ip=$IP"

echo "------------------"
date -u +"%Y-%m-%dT%H:%M:%SZ"
echo GET $URL
curl $URL
printf "\n"
