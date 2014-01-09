#!/bin/sh

# This script creates the jail flavours, create a master jail, a build
# jail, configure pf and activate it, and configure bind inside the
# master jail.

. parameters.sh
. utils.sh


echo "Installing packages"
check pkg install jailaudit ezjail


echo "Setting up ezjail"
echo 'ezjail_enable="YES"' >> /etc/rc.conf
echo 'ezjail_use_zfs="YES"' >> /usr/local/etc/ezjail.conf
echo 'ezjail_jailzfs="zroot/ezjail"' >> /usr/local/etc/ezjail.conf
echo 'ezjail_use_zfs_for_jails="YES' >> /usr/local/etc/ezjail.conf
check ezjail-admin install


echo "Setting up flavours"

# default flavour
check mkdir -p /usr/jails/flavours/default/{etc,etc/rc.d}
check cp /usr/jails/flavours/{example,default}/etc/make.conf
check cp /usr/jails/flavours/{example,default}/etc/rc.conf
check cp /usr/jails/flavours/{example,default}/etc/periodic.conf
check cp /etc/resolv.conf /usr/jails/flavours/default/etc/resolv.conf

# master flavour
check cp -Rp /usr/jails/flavours/default /usr/jails/flavours/master

# build flavour
check cp -Rp /usr/jails/flavours/default /usr/jails/flavours/build

# slave flavour
check cp -Rp /usr/jails/flavours/default /usr/jails/flavours/slave


echo "Creating new interface"
echo 'cloned_interfaces="lo1"' >> /etc/rc.conf
echo 'ifconfig_lo1="inet 172.16.0.1 netmask 255.255.255.0' >> /etc/rc.conf
check ifconfig lo1 create inet 172.16.0.1 netmask 255.255.255.0


echo "Creating master jail (172.16.0.254)"
check ezjail-admin create -f master master "lo1|172.16.0.254"


echo "Creating build jail (172.16.0.253)"
check ezjail-admin create -f build buld "lo1|172.16.0.253"


echo "Setting up pf"
check cp pf.conf /etc/

ask "Do you want to review /etc/pf.conf before activating pf?" "y"
if [ "$ANSWER" = "y" ]; then
    $EDITOR /etc/pf.conf
fi

fail_if_no "Continue?" "y"

echo "Activating pf"
echo 'pf_enable="YES"' >> /etc/rc.conf
kldload pf.ko
pfctl -F all -f /etc/pf.conf
