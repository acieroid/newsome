#!/bin/sh
set -o errexit
set -o nounset

# ezjail setup
pkg install -y ezjail
echo 'ezjail_enable="YES"' >> /etc/rc.conf
echo 'ezjail_use_zfs="YES"' >> /usr/local/etc/ezjail.conf
echo 'ezjail_jailzfs="zroot/ezjail"' >> /usr/local/etc/ezjail.conf
echo 'ezjail_use_zfs_for_jails="YES"' >> /usr/local/etc/ezjail.conf

ezjail-admin install

# default flavour
mkdir -p /usr/jails/flavours/default/etc /etc/rc.d
cp /usr/jails/flavours/example/etc/make.conf /usr/jails/flavours/default/etc/make.conf
cp /usr/jails/flavours/example/etc/rc.conf /usr/jails/flavours/default/etc/rc.conf 
cp /usr/jails/flavours/example/etc/periodic.conf /usr/jails/flavours/default/etc/periodic.conf
cp /etc/resolv.conf /usr/jails/flavours/default/etc/resolv.conf
# As of FreeBSD 10, pkg_add does not exist and it doesn't seem to be possible to
# automatically setup pkg in a jail
#cp /usr/jails/flavours/example/etc/rc.d/ezjail.flavour.example  /usr/jails/flavours/default/etc/rc.d/ezjail.flavour.example
#cd /usr/jails/flavours/default/pkg
#REPO=$(pkg -vv | grep pkg.FreeBSD.org | sed -E 's|.*(http://.*/latest).*|\1|g')
#PKGVERSION=$(pkg info pkg | grep Version | cut -d':' -f 2 | cut -c2-)
#fetch "$REPO/All/pkg-$PKGVERSION.txz"

# master flavour
cp -Rp /usr/jails/flavours/default /usr/jails/flavours/master

# slave flavour
cp -Rp /usr/jails/flavours/default /usr/jails/flavours/slave
mkdir -p /usr/jails/flavours/slave/root/bin
cp -Rp ../service-utils/*.sh /usr/jails/flavours/slave/root/bin

# pf
echo 'pf_enable="YES"' >> /etc/rc.conf
kldload pf.ko # TODO: replace by service pf start ?

echo 'cloned_interfaces="lo1"' >> /etc/rc.conf
echo 'ifconfig_lo1="inet 172.16.0.1 netmask 255.255.255.0"' >> /etc/rc.conf
ifconfig lo1 create inet 172.16.0.1 netmask 255.255.255.0

# TODO: adapt the pf.conf with the machine configuration (interface, ip, etc.)
cp pf.conf /etc/pf.conf
pfctl -F all -f /etc/pf.conf

# master jail
ezjail-admin create -f master master "lo1|172.16.0.1"
ezjail-admin start master
ezjail-admin console -e "pkg" master # answer y

# unbound in master: TODO
#ezjail-admin console -e "fetch ftp://ftp.internic.net/domain/named.cache" master
#ezjail-admin console -e "mv named.cache /etc/unbound/root.hints" master

# nginx in master
# TODO: ssl (one per subdomain)
# TODO: replace error pages nicer pages (eg. 502 should tell "this service is
# not runnig")
ezjail-admin console -e "pkg -y install nginx" master
cp master-nginx.conf /usr/jails/master/usr/local/etc/nginx/nginx.conf
mkdir -p /usr/jails/master/usr/local/www/master/
cp master-index.html /usr/jails/master/usr/local/www/master/index.html
mkdir -p /usr/jails/master/usr/local/www/catchall/
cp master-catchall-index.html /usr/jails/master/usr/local/www/catchall/index.html
echo 'nginx_enable="YES"' >> /usr/jails/master/etc/rc.conf
ezjail-admin console -e "service nginx start" master

# install service/jail manipulation utilities
mkdir -p /root/bin
cp ../service-utils/* /root/bin

# supervisord
pkg install -y py27-supervisor
echo 'supervisord_enable="YES"' >> /etc/rc.conf
cp supervisord.conf /usr/local/etc/supervisord.conf
mkdir /usr/local/etc/supervisord.d/
service supervisord start
