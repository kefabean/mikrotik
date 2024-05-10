# DHCP lease script to send alert when new device is added to the network

# Only add DNS record when registering DHCP client as deregistering usually immediately precedes a registration.
:if ($leaseBound = "1") do={

   # define leaseHostname to avoid hyphenated variable names
   :local leaseHostname $"lease-hostname"

   # create safe 'MAC' address without colons
   :local a $leaseActMAC
   :local b ":"
   :while condition=[find $a $b] do={
      :set $a ("$[:pick $a 0 ([find $a $b]) ]"."$[:pick $a ([find $a $b]+1) ([:len $a]) ]")
   }
   :local safeMAC $a

   # create default fqdn for devices with blank hostname
   :local fqdn
   :if ([:len $leaseHostname] > 0) do={
      :set fqdn "$leaseHostname.$leaseServerName"
   } else={
      :set fqdn "unknown-$safeMAC.$leaseServerName"
   }

   :log info "FQDN: $fqdn IP: $leaseActIP MAC: $leaseActMAC"

   # Set a comment that identifies the DNS record by DHCP server and MAC address
   :local leaseComment "dhcp-script-managed-$leaseServerName-$leaseActMAC"

   # Remove existing DNS records linked to the MAC address except those with current hostname and IP address
   :foreach dns in=[/ip/dns/static/find comment~"$leaseActMAC" and (address!="$leaseActIP" or name!="$fqdn")] do={
      :log info "Removing DNS record: $fqdn = $leaseActIP for $leaseActMAC MAC address"
      /ip/dns/static/remove $dns
   }

   # Remove all managed DNS records for which the dhcp leases have expired
   # TODO!!!

   # If the registration details exactly matches an existing DNS record do nothing
   :if ([:len [/ip dns static find comment="$leaseComment" and address="$leaseActIP" and name="$fqdn"]] = 1) do={
      :log info "DNS record: $fqdn = $leaseActIP already exists for $leaseActMAC MAC address - no action required"
   }
   # If no matching DNS record exists, create one and send email notification
   :if ([:len [/ip dns static find comment="$leaseComment" and address="$leaseActIP" and name="$fqdn"]] = 0) do={
      :delay 1
      /ip dns static add comment="$leaseComment" address="$leaseActIP" name="$fqdn" ttl="00:05:00"
      /tool e-mail send to="daniel@kefa.uk" subject="Alert - New device added ($fqdn)" body="New DNS record created:\n\n$fqdn = $leaseActIP ($leaseActMAC)"
   }
}
