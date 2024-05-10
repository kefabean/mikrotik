#!/bin/bash

# Script uses ssh to copy the same dhcp lease-script to each of the dhcp servers configured on the Mikrotik
# Script needs to escape out newlines, double quotes and dollar signs to work

DHCP_SERVERS=$(ssh admin@router.lan '/ip/dhcp-server/print proplist="name"' | grep -v NAME | awk -F' ' '{print $2}' | tr '\n\r' '\n')
SCRIPT=$(cat dhcp-managed-dns-records.sh | sed 's/\\n/\\\\n/g' | sed 's/$/\\n/g' | sed 's/\(["$]\)/\\\1/g' | tr -d '\n')

for DHCP_SERVER in $DHCP_SERVERS; do
   echo $DHCP_SERVER
   ssh admin@router.lan "/ip/dhcp-server/set $DHCP_SERVER lease-script=\"$SCRIPT\""
done
