# DHCP lease script to send alert when new device is added to the network

# Only add DNS record when registering DHCP client as deregistering usually immediately precedes a registration.
:if ($leaseBound = "1") do={

   # define leaseHostname to avoid hyphenated variable names
   :local leaseHostname $"lease-hostname"

   # create safe 'MAC' address without colons
   :local safeMAC $leaseActMAC
   :while condition=[find $safeMAC ":"] do={
      :set $safeMAC ("$[:pick $safeMAC 0 ([find $safeMAC ":"]) ]"."$[:pick $safeMAC ([find $safeMAC ":"]+1) ([:len $safeMAC]) ]")
   }

   # create default fqdn for devices with blank hostname
   :local fqdn
   :if ([:len $leaseHostname] > 0) do={
      :set fqdn "$leaseHostname.$leaseServerName"
   } else={
      :set fqdn "unknown-$safeMAC.$leaseServerName"
   }

   # Set a comment that identifies the DNS record by DHCP server and MAC address
   # WARNING: do not modify format of comment as script (remove-dns-for-expired-dhcp-lease.rsc)
   # will fail as it expects specific format
   :local leaseComment "dhcp-script-managed-$leaseActMAC-$leaseServerName"

   # Remove existing DNS records linked to the MAC address except those with current hostname and IP address
   :foreach dns in=[/ip/dns/static/find comment~"$leaseActMAC" and (address!="$leaseActIP" or name!="$fqdn")] do={
      :log info "Removing DNS record: $fqdn = $leaseActIP for $leaseActMAC MAC address"
      /ip/dns/static/remove $dns
   }

   # If the registration details exactly matches an existing DNS record do nothing
   :if ([:len [/ip dns static find comment="$leaseComment" and address="$leaseActIP" and name="$fqdn"]] = 1) do={
      :log info "DNS record: $fqdn = $leaseActIP already exists for $leaseActMAC MAC address - no action required"
   }
   # If no matching DNS record exists, create one and send email notification
   :if ([:len [/ip dns static find comment="$leaseComment" and address="$leaseActIP" and name="$fqdn"]] = 0) do={
      :delay 1

      # generate friendly dates and times to include in email
      :local months [:toarray "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec"]
      :local year [:pick [/system/clock/get date] 0 4]
      :local month [:pick $months ([:tonum [:pick [/system/clock/get date] 5 7]] - 1)]
      :local day [:pick [/system/clock/get date] 8 10]
      :local time [:pick [/system/clock/get time] 0 5]

      :log info "Adding DNS record for $fqdn = $leaseActIP ($leaseActMAC)"
      /ip dns static add comment="$leaseComment" address="$leaseActIP" name="$fqdn" ttl="00:05:00"
      /tool e-mail send to="daniel@kefa.uk" subject="Alert - New device added ($fqdn)" body="New DNS record created on $day $month $year at $time:\n\n$fqdn = $leaseActIP ($leaseActMAC)"
   }
}
