# ezjail setup
pkg install -y ezjail
echo 'ezjail_enable="YES"' >> /etc/rc.conf
echo 'ezjail_use_zfs="YES"' >> /usr/local/etc/ezjail.conf
echo 'ezjail_jailzfs="zroot/ezjail"' >> /usr/local/etc/ezjail.conf
echo 'ezjail_use_zfs_for_jails="YES"' >> /usr/local/etc/ezjail.conf

ezjail-admin install

# default flavour
mkdir -p /usr/jails/flavours/default/{etc,etc/rc.d}
cp /usr/jails/flavours/{example,default}/etc/make.conf
cp /usr/jails/flavours/{example,default}/etc/rc.conf
cp /usr/jails/flavours/{example,default}/etc/periodic.conf
cp /etc/resolv.conf /usr/jails/flavours/default/etc/resolv.conf

# master flavour
cp -Rp /usr/jails/flavours/default /usr/jails/flavours/master

# slave flavour
cp -Rp /usr/jails/flavours/default /usr/jails/flavours/slave

# pf
echo 'pf_enable="YES"' >> /etc/rc.conf
kldload pf.ko

echo 'cloned_interfaces="lo1"' >> /etc/rc.conf
echo 'ifconfig_lo1="inet 172.16.0.1 netmask 255.255.255.0' >> /etc/rc.conf
ifconfig lo1 create inet 172.16.0.1 netmask 255.255.255.0

# TODO: copy pf.conf
# pfctl -F all -f /etc/pf.conf

# master jail
# ezjail-admin create -f master master "lo1|10.0.0.2"
