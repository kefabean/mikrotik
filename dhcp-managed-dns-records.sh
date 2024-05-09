
# REFERENCE: internal global dhcp variables
#
# leaseBound - set to "1" if bound, otherwise set to "0"
# leaseServerName - dhcp server name
# leaseActMAC - active mac address
# leaseActIP - active IP address
# lease-hostname - client hostname
# lease-options - array of received options

# define new variable to avoid hyphenated variable names
:local leaseHostname $"lease-hostname"
# define a comment that uniquely identifies the DNS record by DHCP server and MAC address
# allows us to detect and stale DNS records for expired DHCP leases
:local leaseComment "dhcp-script-managed-$leaseServerName-$leaseActMAC"
# allow us to iterate over hostnames with and without various suffixes
:local leaseHostnames ("$leaseHostname.$leaseServerName,$leaseHostname")

:log info "leaseBound: $leaseBound\nleaseServerName: $leaseServerName\nleaseActMAC: $leaseActMAC\nleaseActIP: $leaseActIP\nlease-hostname: $leaseHostname"

# remove all existing DNS records associated with the MAC address except for ones with the current hostnames and IP address
:foreach dnsRecord in=[/ip dns static find comment~"$leaseActMAC" and address!="$leaseActIP" or name!="$h"] do={

}

# remove all managed DNS records for which the dhcp leases have expired

# only add DNS records if we are registering a DHCP client. Deregistering doesn't 
# actually expire the DHCP lease and usually immediately precedes a registration.
# Don't add a new DNS record if it already exists and exactly matches.
:if ($leaseBound = "1") do={
  # remove all DNS records that don't have a corresponding DHCP lease (eg. lease has expired)
  # some statements
  :foreach h in=[:toarray value="$leaseHostnames"] do={
    # if the new registration exactly matches an existing DNS record do nothing
    :if ([:len [/ip dns static find comment="$leaseComment" and address="$leaseActIP" and name="$h"]] = 1) do={
      :log info "Reregistering DHCP client where associated DNS record already exists"
    }
    # if there is no existing matching DNS record, create one and send email notification
    :if ([:len [/ip dns static find comment="$leaseComment" and address="$leaseActIP" and name="$h"]] = 0) do={
      :delay 1
      /ip dns static add comment="$leaseComment" address="$leaseActIP" name="$h" ttl="00:05:00"
      /tool e-mail send to="daniel@kefa.uk" subject="Alert - New device added ($h)" body="New device registered.\nhostname: $h\nMAC address: $leaseActMAC\ndhcp server: $leaseServerName\n ip address: $leaseActIP"
    }
  }
}



# for securely accessing servers use the DNS name that includes the vlan
# suffix (eg. remote.home) instead of the convenience hostname (eg. remote)
# this can't be accidently overwritten by a device in another vlan (eg. a guest device)
:local leaseHostnames ("$leaseHostname.$leaseServerName,$leaseHostname")

:if ([:len [/ip dns static find comment~"$leaseComment.*" and address="$leaseActIP"]] > 0)

# remove all DNS entries with IP address of DHCP lease
/ip dns static remove [/ip dns static find comment="$leaseComment" and address="$leaseActIP"]
:foreach h in=[:toarray value="$leaseHostnames"] do={
  # remove all DNS entries with hostname of DHCP lease
  /ip dns static remove [/ip dns static find comment="$leaseComment" and name="$h"]
  /ip dns static remove [/ip dns static find comment="$leaseComment" and address="$leaseActIP" and name="$h"]
  :if (($leaseBound = "1") && ([:len $leaseHostname] > 0)) do={
    :delay 1
    /ip dns static add comment="$leaseComment" address="$leaseActIP" name="$h" ttl="00:05:00"
    /tool e-mail send to="daniel@kefa.uk" subject="Alert - new device added ($leaseHostname)" body="A new device $leaseHostname with MAC address $leaseActMAC has been added to the $leaseServerName network and has been assigned the $leaseActIP IP address."
  }
}
