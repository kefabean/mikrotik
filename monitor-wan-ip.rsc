# Script to monitor the IP address of the WAN port
# and send an email alert if it changes

:global actualIP

:local newIP [/ip address get [find interface="pppoe-out1"] address]

:if ($newIP != $actualIP) do={
   # generate friendly dates and times to include in email
   :local months [:toarray "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec"]
   :local year [:pick [/system/clock/get date] 0 4]
   :local month [:pick $months ([:tonum [:pick [/system/clock/get date] 5 7]] - 1)]
   :local day [:pick [/system/clock/get date] 8 10]
   :local time [:pick [/system/clock/get time] 0 5]

   :put "ip address $actualIP changed to $newIP"
   :set actualIP $newIP
   /tool e-mail send to="daniel@kefa.uk" subject="Alert - WAN IP address change from $actualIP to $newIP" body="WAN IP address change on $day $month $year at $time:\n\nfrom: $actualIP\nto: $newIP"
} else={
   :log info "WAN IP address remains unchanged: $actualIP"
}
