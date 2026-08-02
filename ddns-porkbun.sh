#!/bin/bash

# Porkbun Dynamic DNS Updater
# Updates a DNS A record with your current public IP address
# Note that it only calls porkbun if the public ip address changes, so it can be run every minute if you like

unset PATH	# avoid accidental use of $PATH

# ------------- system commands used by this script --------------------
CAT=/bin/cat;
CP=/bin/cp;
CURL=/bin/curl;
DATE=/bin/date;
DIRNAME=/usr/bin/dirname;
ECHO=/bin/echo;
GREP=/bin/grep;
PWD=/bin/pwd;
READLINK=/usr/bin/readlink;
TEE=/usr/bin/tee;

# Configuration
DOMAIN=${1:-"$DDNS_SUBDOMAIN"};
SUBDOMAIN=${2:-"$DDNS_DOMAIN"};
API_KEY=${3:-"$DDNS_PUBLICKEY"};
SECRET_API_KEY=${4:-"$DDNS_PRIVATEKEY"};
SAVEIP="currentip";		# the filename to save the current ip address to
LOGFILE=porkbun.last;		# save the log file to this file
# End of User Configurable Options

SET_URL="https://api.porkbun.com/api/json/v3/dns/editByNameType/$DOMAIN/A/$SUBDOMAIN";
GET_URL="https://api.porkbun.com/api/json/v3/dns/retrieveByNameType/$DOMAIN/A/$SUBDOMAIN";

# get the current directory
#DIR="$( cd "$( $DIRNAME "${BASH_SOURCE[0]}" )" && $PWD )";
dirx="$($DIRNAME -- $($READLINK -fn -- "$0"; $ECHO x))";
DIR="${dirx%x}";
cd $DIR

# Get time
D="$(TZ=Europe/Paris $DATE)";
$ECHO "$0 Started on $D from $DIR" | $TEE $LOGFILE;

# Get current public IP - thanks api.ipify.org!
CURRENT_IP=$($CURL -s https://api.ipify.org);

if [ -z "$CURRENT_IP" ]; then
	$ECHO "Error: Could not retrieve current IP address" | $TEE -a $LOGFILE;
	exit 1
fi

$ECHO "Current public IP: $CURRENT_IP" | $TEE -a $LOGFILE;

LAST_IP="";
if [ -f $SAVEIP ] ; then
	LAST_IP=$($CAT $SAVEIP);
fi
if [ "$CURRENT_IP" == "$LAST_IP" ] ; then
	$ECHO "IP Address $CURRENT_IP has not changed - no update done" | $TEE -a $LOGFILE;
	exit 1;
fi

$ECHO "IP Address Changed from $LAST_IP to $CURRENT_IP - Updating PorkBun at $SET_URL" | $TEE -a $LOGFILE;
# Prepare JSON payload
JSON_DATA=$($CAT <<EOF
{
	"secretapikey": "$SECRET_API_KEY",
	"apikey": "$API_KEY",
	"content": "$CURRENT_IP",
	"ttl": "600"
}
EOF
);

# First Read the ip address
RESPONSE=$($CURL -s -X POST "$GET_URL" \
	-H "Content-Type: appli$CATion/json" \
	-d "$JSON_DATA")

MATCH='"content":"'$CURRENT_IP'"';
if [[ $RESPONSE =~ $MATCH ]] ; then
	$ECHO "PorkBun IP Address is already $CURRENT_IP - no update done" | $TEE -a $LOGFILE;
	$ECHO $CURRENT_IP > $SAVEIP;
else
	$ECHO "Previous Value: $RESPONSE" | $TEE -a $LOGFILE;
	# Make API request
	RESPONSE=$($CURL -s -X POST "$SET_URL" \
		-H "Content-Type: appli$CATion/json" \
		-d "$JSON_DATA")

	$ECHO $RESPONSE | $TEE -a $LOGFILE;
	# Check response
	if $ECHO "$RESPONSE" | $GREP -q '"status":"SUCCESS"'; then
		$ECHO $CURRENT_IP > $SAVEIP;
		$ECHO "Success: DNS record updated to $CURRENT_IP" | $TEE -a $LOGFILE;
	else
		$ECHO "Error: Failed to update DNS record" | $TEE -a $LOGFILE;
		$ECHO "Response: $RESPONSE" | $TEE -a $LOGFILE;
		exit 1;
	fi
	$CP $LOGFILE ${LOGFILE}chg;
fi

exit 0;
