#!/bin/sh
set -o errexit
set -o nounset

if [ "$TERM" != "screen" ] && [ ! `tty | grep /dev/tty` ]; then
    echo 'You should avoid running this script from a ssh connection'
    echo 'as when launching pf the connection might be broken.'
    echo 'Use a real tty, or launch from screen/tmux.'
    echo ''
    echo 'Press enter to continue (^C to abort)'
    read tmp
fi

# load configuration
. ./parameters.sh

# ntpd
# /usr/sbin/ntpd & /etc/ntp.conf should already be there; just enable
if [ -z $(grep ntpd /etc/rc.conf) ]; then
    echo 'ntpd_enable="YES"' >> /etc/rc.conf
    cp ntp.conf /etc/ntp.conf
fi

# disable sendmail
if [ -n $(grep sendmail_enable /etc/rc.conf) ]; then
    sed -i '/^sendmail_enable/ s/=.*/"NONE"/' /etc/rc.conf
else
    echo 'sendmail_enable="NONE"' >> /etc/rc.conf
fi

# ezjail setup
pkg install -y ezjail
echo 'ezjail_enable="YES"' >> /etc/rc.conf
#echo 'ezjail_use_zfs="YES"' >> /usr/local/etc/ezjail.conf
#echo 'ezjail_jailzfs="zroot/ezjail"' >> /usr/local/etc/ezjail.conf
#echo 'ezjail_use_zfs_for_jails="YES"' >> /usr/local/etc/ezjail.conf

ezjail-admin install

# default flavour
mkdir -p /usr/jails/flavours/default/etc /etc/rc.d
cp /usr/jails/flavours/example/etc/make.conf /usr/jails/flavours/default/etc/make.conf
cp /usr/jails/flavours/example/etc/rc.conf /usr/jails/flavours/default/etc/rc.conf
echo 'sshd_enable="YES"' >> /usr/jails/flavours/default/etc/rc.conf
cp /usr/jails/flavours/example/etc/periodic.conf /usr/jails/flavours/default/etc/periodic.conf
cp /etc/resolv.conf /usr/jails/flavours/default/etc/resolv.conf
cp /etc/login.conf /usr/jails/flavours/default/etc/login.conf
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
cp -Rp ../service-utils/*.py /usr/jails/flavours/slave/root/bin

# pf & network
echo "cloned_interfaces=\"$JINTERFACE\"" >> /etc/rc.conf
echo "ifconfig_$JINTERFACE=\"inet $JMIP netmask 255.255.255.0\"" >> /etc/rc.conf
ifconfig $JINTERFACE create inet $JMIP netmask 255.255.255.0

# TODO: drop in editor
mkpf() {
    cat <<EOF
# Interfaces
ext_if = "$INTERFACE"
int_if = "$IINTERFACE"
jail_if= "$JINTERFACE"

# IPs
ext_ip = "$IP"
jail_ips = "$JIPS"
jail_master_ip = "$JMIP"
jail_users_ip = "$JUIP"

EOF
    cat pf.conf.partial
}
mkpf >  pf.conf.gen
echo 'Generated pf.conf:'
echo '--- pf.conf START ---'
cat pf.conf.gen
echo '--- pf.conf END ---'
echo 'Is this OK? (Enter to continue, ^C to abort)'; read tmp

cp pf.conf.gen /etc/pf.conf
echo 'pf_enable="YES"' >> /etc/rc.conf
echo "WARNING: The connection might close here.
If it is the case, reconnect and reattach tmux (with tmux a).
Press enter to continue"; read tmp
service pf start

# master jail
ezjail-admin create -f master master "$JINTERFACE|$JMIP"
ezjail-admin start master
ezjail-admin console -e "pkg update" master # answer y

ezjail-admin console -e "pkg install -y nsd" master
echo 'nsd_enable="YES"' >> /usr/jails/master/etc/rc.conf
ezjail-admin console -e "nsd-control-setup" master
sed "s/MAIN_DOMAIN/$MAIN_DOMAIN/g;s/MASTER_OUT_IP/$IP/g" nsd.conf > /usr/jails/master/usr/local/etc/nsd/nsd.conf
sed "s/MAIN_DOMAIN/$MAIN_DOMAIN/g;s/MASTER_OUT_IP/$IP/g" main.zone > "/usr/jails/master/usr/local/etc/nsd/${MAIN_DOMAIN}.zone"
ezjail-admin console -e "service nsd start" master

# nginx in master
# TODO: ssl (one per subdomain)
# TODO: replace error pages with nicer pages (eg. 502 should tell "this service
# is not runnig", however in this case it should be handled by the conf in
# nginx/services.d)
ezjail-admin console -e "pkg install -y nginx" master
sed "s/MAIN_DOMAIN/$MAIN_DOMAIN/g;s/JUIP/$JUIP/g" master-nginx.conf > /usr/jails/master/usr/local/etc/nginx/nginx.conf
mkdir /usr/jails/master/usr/local/www/master/
cp master-index.html /usr/jails/master/usr/local/www/master/index.html
mkdir /usr/jails/master/usr/local/www/catchall/
cp master-catchall-index.html /usr/jails/master/usr/local/www/catchall/index.html
echo 'nginx_enable="YES"' >> /usr/jails/master/etc/rc.conf
# We let FreeBSD's service mechanism handle nginx
ezjail-admin console -e "service nginx start" master

# static jail
ezjail-admin create -f slave static "$JINTERFACE|$JSIP"
ezjail-admin start static
ezjail-admin console -e "pkg install -y nginx" static
cp static-nginx.conf /usr/jails/static/usr/local/etc/nginx/nginx.conf
# TODO: error pages
mkdir /usr/jails/static/usr/local/www/catchall/
cp static-catchall-index.html /usr/jails/static/usr/local/www/catchall/index.html
echo 'nginx_enable="YES"' >> /usr/jails/static/etc/rc.conf
ezjail-admin console -e "service nginx start" static
ezjail-admin console -e "pw group add service" static
cp ../service-utils/service-jail-action.sh /usr/jails/static/usr/local/bin/
chmod +x /usr/jails/static/usr/local/bin/service-jail-action.sh

# install service/jail manipulation utilities
mkdir -p /root/bin
cp ../service-utils/*.sh /root/bin
cp ../service-utils/*.py /root/bin
chmod +x /root/bin/*.sh

# supervisord
pkg install -y py27-supervisor
echo 'supervisord_enable="YES"' >> /etc/rc.conf
cp supervisord.conf /usr/local/etc/supervisord.conf
mkdir /usr/local/etc/supervisord.d/
service supervisord start

# enable service manager
echo "[program:service-manager]
command=/usr/local/bin/python2.7 /root/bin/service-manager.py
" > "/usr/local/etc/supervisord.d/main_service-manager.ini"
supervisorctl reread
supervisorctl update

# add users jail
ezjail-admin create -f slave users "$JINTERFACE|$JUIP"
ezjail-admin start users
ezjail-admin console -e "pkg install -y nginx tmux" users
cp users-nginx.conf /usr/jails/users/usr/local/etc/nginx/nginx.conf
echo 'nginx_enable="YES"' >> /usr/jails/users/etc/rc.conf
ezjail-admin console -e "service nginx start" users
echo "Post-installation done. Launch 'ezjail-admin console -e adduser users' to add users"

# configuration of freebsd-update
sed -i 's|^Components.*|Components world/base kernel|' /etc/freebsd-update.conf

# add admin
pw useradd -n admin -u 999 -G wheel -m -s csh
echo 'Please enter a public SSH key used to login as admin: '
read ssh_key
mkdir -p /home/admin/.ssh/
echo $ssh_key > /home/admin/.ssh/authorized_keys

# disable root login
grep -v PermitRootLogin /etc/ssh/sshd_config > /tmp/sshd_config
echo 'PermitRootLogin no' >> /tmp/sshd_config
echo 'PasswordAuthentication no' >> /tmp/sshd_config
mv /tmp/sshd_config /etc/ssh/sshd_config
service sshd reload
