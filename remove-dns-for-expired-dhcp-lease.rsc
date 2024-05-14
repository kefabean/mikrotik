# System script to run once a day and remove static DNS entries corresponding to
# DHCP leases that have expired eg. can no longer be found.

:local address
:local name
:local hostname
:local comment
:local mac
:local server
:local numLease

# generate friendly dates and times to include in email
:local months [:toarray "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec"]
:local year [:pick [/system/clock/get date] 0 4]
:local month [:pick $months ([:tonum [:pick [/system/clock/get date] 5 7]] - 1)]
:local day [:pick [/system/clock/get date] 8 10]
:local time [:pick [/system/clock/get time] 0 5]
:local count 0

:foreach record in=[/ip/dns/static/find comment~"dhcp-script-managed-"] do={
   :set comment [/ip/dns/static/get number="$record" value-name="comment"]
   # extract mac address from fixed position in comment
   :set mac [:pick $comment 20 37]
   # extract dhcp server name from fixed position in comment
   :set server [:pick $comment 38 60]
   :set address [/ip/dns/static/get number="$record" value-name="address"]
   :set name [/ip/dns/static/get number="$record" value-name="name"]
   :if ($name~"unknown-") do={
      :set name ".$server"
   }
   :set hostname [:pick $name 0 [:find $name "."]]
   :set numLease [:len [/ip/dhcp-server/lease/find mac-address="$mac" address="$address" host-name="$hostname"]]
   :if ($numLease = 0) do={
      :log info "Deleting DNS record for $name = $address ($mac)"
      :set count ($count + 1)
      /ip/dns/static/remove numbers="$record"
      /tool e-mail send to="daniel@kefa.uk" subject="Alert - Device no longer seen ($name)" body="DNS record deleted on $day $month $year at $time:\n\n$name = $address ($mac)"
   }
}

:if ($count = 0) do={
   :log info "dns-cleanup-script ran but no DNS records removed."
}
