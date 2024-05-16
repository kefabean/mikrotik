#!/bin/bash

# Installs dhcp-managed-dns-records.rsc lease-script on Mikrotik via SSH
# where multiple dhcp servers are configured.
# Script escapes newlines, double quotes and dollar signs, but preserves '\n' newline characters in scripts.
# Also installs dhcp-cleanup-script that can be run daily to delete DNS entries for
# IP addresses where no DHCP lease exists.

DHCP_SERVERS=$(ssh admin@router.lan '/ip/dhcp-server/print proplist="name"' | grep -v NAME | awk -F' ' '{print $2}' | tr '\n\r' '\n')
DHCP_SCRIPT=$(cat dhcp-managed-dns-records.rsc | sed 's/\\n/\\\\n/g' | sed 's/$/\\n/g' | sed 's/\(["$]\)/\\\1/g' | tr -d '\n')

for DHCP_SERVER in $DHCP_SERVERS; do
   echo "Updating script for dhcp server: $DHCP_SERVER"
   ssh admin@router.lan "/ip/dhcp-server/set $DHCP_SERVER lease-script=\"$DHCP_SCRIPT\""
done

for SCRIPT_NAME in dns-cleanup.rsc monitor-wan-ip.rsc; do
   echo "Updating $SCRIPT_NAME"
   SCRIPT_CONTENT=$(cat $SCRIPT_NAME | sed 's/\\n/\\\\n/g' | sed 's/$/\\n/g' | sed 's/\(["$]\)/\\\1/g' | tr -d '\n')
   echo "Ignore 'no such item' message if displayed on next line."
   ssh admin@router.lan "/system/script/remove $SCRIPT_NAME"
   ssh admin@router.lan "/system/script/add name=\"$SCRIPT_NAME\" source=\"$SCRIPT_CONTENT\""
done
