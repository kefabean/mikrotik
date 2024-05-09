# define new variable to avoid hyphenated variable names
:local leaseHostname $"lease-hostname"
:local fqdn "$leaseHostname.$leaseServerName"

:if ([:len $leaseHostname] > 0) do={
   # define a comment that identifies the DNS record by DHCP server and MAC address
   # allows us to detect and stale DNS records for expired DHCP leases
   :local leaseComment "dhcp-script-managed-$leaseServerName-$leaseActMAC"

   :log info "fqdn: $fqdn\nleaseActIP: $leaseActIP\nleaseActMAC: $leaseActMAC\nleaseBound: $leaseBound"

   # remove all existing DNS records associated with the MAC address except for ones with the current hostnames and IP address
   :foreach dns in=[/ip/dns/static/find comment~"$leaseActMAC" and (address!="$leaseActIP" or name!="$fqdn")] do={
      /ip/dns/static/remove $dns
   }
   # /ip/dns/static/find comment~"$leaseActMAC" and (address!="$leaseActIP" or name!="$fqdn")

   # remove all managed DNS records for which the dhcp leases have expired
   # TODO!!!

   # only add DNS records if we are registering a DHCP client. Deregistering doesn't
   # actually expire the DHCP lease and usually immediately precedes a registration.
   # Don't add a new DNS record if it already exists and exactly matches.
   :if ($leaseBound = "1") do={
      # if the new registration exactly matches an existing DNS record do nothing
      :if ([:len [/ip dns static find comment="$leaseComment" and address="$leaseActIP" and name="$fqdn"]] = 1) do={
         :log info "DNS record: $fqdn = $leaseActIP already exists for $leaseActMAC MAC address - no action required"
      }
      # if there is no existing matching DNS record, create one and send email notification
      :if ([:len [/ip dns static find comment="$leaseComment" and address="$leaseActIP" and name="$fqdn"]] = 0) do={
         :delay 1
         /ip dns static add comment="$leaseComment" address="$leaseActIP" name="$fqdn" ttl="00:05:00"
         /tool e-mail send to="daniel@kefa.uk" subject="Alert - New device added ($fqdn)" body="New DNS record created:\n\n$fqdn = $leaseActIP ($leaseActMAC)"
      }
   }
}


# # remove all DNS entries with IP address of DHCP lease
# /ip dns static remove [/ip dns static find comment="$leaseComment" and address="$leaseActIP"]
# :foreach h in=[:toarray value="$leaseHostnames"] do={
#   # remove all DNS entries with hostname of DHCP lease
#   /ip dns static remove [/ip dns static find comment="$leaseComment" and name="$h"]
#   /ip dns static remove [/ip dns static find comment="$leaseComment" and address="$leaseActIP" and name="$h"]
#   :if (($leaseBound = "1") && ([:len $leaseHostname] > 0)) do={
#     :delay 1
#     /ip dns static add comment="$leaseComment" address="$leaseActIP" name="$h" ttl="00:05:00"
#     /tool e-mail send to="daniel@kefa.uk" subject="Alert - new device added ($leaseHostname)" body="A new device $leaseHostname with MAC address $leaseActMAC has been added to the $leaseServerName network and has been assigned the $leaseActIP IP address."
#   }
# }
