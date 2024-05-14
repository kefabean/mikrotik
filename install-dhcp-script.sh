#!/bin/bash

# Installs dhcp-managed-dns-records.rsc to multiple dhcp servers lease-script on Mikrotik via SSH
# Script needs to escape out newlines, double quotes and dollar signs to work...but it also needs
# to preserve '\n' newline characters used inside the scripts.

DHCP_SERVERS=$(ssh admin@router.lan '/ip/dhcp-server/print proplist="name"' | grep -v NAME | awk -F' ' '{print $2}' | tr '\n\r' '\n')
DHCP_SCRIPT=$(cat dhcp-managed-dns-records.rsc | sed 's/\\n/\\\\n/g' | sed 's/$/\\n/g' | sed 's/\(["$]\)/\\\1/g' | tr -d '\n')

for DHCP_SERVER in $DHCP_SERVERS; do
   echo "Updating script for dhcp server: $DHCP_SERVER"
   ssh admin@router.lan "/ip/dhcp-server/set $DHCP_SERVER lease-script=\"$DHCP_SCRIPT\""
done

echo "Updating dns-cleanup-script"
DNS_CLEANUP_SCRIPT=$(cat remove-dns-for-expired-dhcp-lease.rsc | sed 's/\\n/\\\\n/g' | sed 's/$/\\n/g' | sed 's/\(["$]\)/\\\1/g' | tr -d '\n')
echo "Ignore 'no such item' message if displayed on next line."
ssh admin@router.lan "/system/script/remove dns-cleanup-script"
ssh admin@router.lan "/system/script/add name=\"dns-cleanup-script\" source=\"$DNS_CLEANUP_SCRIPT\""
