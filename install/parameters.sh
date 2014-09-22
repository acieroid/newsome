######################################################################
##                          Parameters                              ##
######################################################################

# The installation will completely wipe out the content of this disk
DISK="ada0"

# The machine's hostname
# On a kimsufi, set it to your kimsufi's name (ks123456.kimsufi.com)
HOSTNAME="newsome"

# Main domain of the machine (eg. awesom.eu)
MAIN_DOMAIN="home.lan"

# The name of the ethernet interface
# Do `ifconfig` or `ip link` to find it
INTERFACE="rl0"

# Static IP address
# (XXX Set to DHCP to have a dynamic one; messing up with pf.conf)
# On a kimsufi, look at your current IP (`ifconfig` or `ip addr`)
# IP="inet 192.168.1.100 netmask 255.255.255.0 broadcast 192.168.1.255"
IP="192.168.2.235"

# Jail IPs
JIPS="172.16.0.0/24"
# Jail Master IP
JMIP="172.16.0.1"
# Jail Static IP
JSIP="172.16.0.2"
# JAil Users IP
JUIP="172.16.0.3"

# Jail network interface
JINTERFACE="lo1"

# Internal interface (local loop)
IINTERFACE="lo0"

# Address of the router
# Generally the /24 of your IP followed by .1
# On a kimsufi, the /24 of your IP followed by .254
ROUTER="192.168.2.1"

# Size of the swap partition
# Depends on the usage. Generally 2 times the RAM size is good.
# On a kimsufi, 4G is fine
SWAPSIZE="1G"

# FreeBSD version
FREEBSD_VERSION="10.0-RELEASE"

# Architecture
ARCH="$(uname -m)"

# DNS server to use
DNS="8.8.8.8"

# Debug mode (YES to activate it)
DEBUG="NO"

# Editor to edit files
EDITOR="vi"
