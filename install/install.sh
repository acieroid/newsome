#!/bin/sh

# This script performs a clean install of FreeBSD, using ZFS. It can
# be run on a mfsBSD or on a kimsufi in FreeBSD rescue mode for
# example.

# To use:
# scp install.sh parameters.sh root@ip:
# ssh root@ip # mfsbsd connects with dhcp, root password: mfsroot
# vi parameters.sh
# sh install.sh

######################################################################
##                     Load Configuration file                      ##
######################################################################

. ./parameters.sh # exit by itself.

######################################################################
##                             Utils                                ##
######################################################################

ask () {
    QUESTION="$1"
    DEFAULT="$2"
    echo -n "$QUESTION"
    if [ "$DEFAULT" = "y" ]; then
        echo -n " [Y/n] "
    else
        echo -n " [y/N] "
    fi

    read ANSWER

    while [ "$ANSWER" != "y" -a "$ANSWER" != "n" ]; do
        echo -n "Please answer y or n: "
        read ANSWER
        if [ "$ANSWER" = "" ]; then
            ANSWER=DEFAULT
        fi
    done
}

fail_if_no () {
    ask "$1" "$2"
    if [ "$ANSWER" = "n" ]; then
        exit 1
    fi
}

check () {
    CMD="$@"
    echo "$CMD"
    $CMD
    if [ "$?" != 0 ]; then
        echo "ERROR: command $CMD failed, stopping"
        exit 1
    fi
    if [ "$DEBUG" = "YES" ]; then
        echo "done, press enter to continue"
        read foo
    fi
}

check_prev () {
    CMD="$@"
    if [ "$?" != 0 ]; then
        echo "ERROR: command $CMD failed, stopping"
        exit 1
    fi
}

######################################################################
##                     Part 1: check config                         ##
######################################################################
echo "1. Checking configuration"

UID="$(id -u)"
if [ "$UID" != 0 ]; then
    fail_if_no "WARNING: this script should be run as root (and it is \
not). Are you sure you want to continue?" "n"
fi

(gpart list $DISK || gpart create -s gpt $DISK) >/dev/null && gpart list $DISK > /dev/null
if [ "$?" -ne 0 ]; then
    fail_if_no "WARNING: the following disk does not exist: \
$DISK. Are you sure you want to continue?" "n"
fi


fail_if_no "WARNING: this script will erase everything present on the \
following drive: $DISK. Are you OK with that?" "n"

ifconfig "$INTERFACE" > /dev/null
if [ "$?" -ne 0 ]; then
    fail_if_no "WARNING: the following interface does not exist: \
$INTERFACE. Are you sure you want to continue?" "n"
fi

# XXX avoid ICMP? No tools (dig/nslookup/host) for DNS queries.
whois freebsd.org > /dev/null
if [ "$?" -ne 0 ]; then
	fail_if_no "WARNING: apparently outside world (freebsd.org) unreachable. \
Are you sure you want to continue?" "n"
fi

fail_if_no "Please review the following configuration carefully:
    DISK=\"$DISK\"
    HOSTNAME=\"$HOSTNAME\"
    INTERFACE=\"$INTERFACE\"
    IP=\"$IP\"
    ROUTER=\"$ROUTER\"
    SWAPSIZE=\"$SWAPSIZE\"
    FREEBSD_VERSION=\"$FREEBSD_VERSION\"
    ARCH=\"$ARCH\"
If everything is OK, the script will start the installation.
OK?" "n"

######################################################################
##                   Part 2: partition creation                     ##
######################################################################
echo "2. Creating partitions on $DISK"

check gpart destroy -F "$DISK"
check gpart create -s gpt "$DISK"
check gpart add -s 64K -t freebsd-boot "$DISK"
check gpart add -s "$SWAPSIZE" -t freebsd-swap -l swap "$DISK"
check gpart add -t freebsd-zfs -l data "$DISK"
check gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 "$DISK"

######################################################################
##                           Part 3: ZFS                            ##
######################################################################
echo "3. Setting up ZFS"

check zpool create -f -o altroot="$MNT" -o cachefile="$VARTMP/zpool.cache" zroot /dev/gpt/data
check zpool export zroot
check zpool import -o altroot="$MNT" -o cachefile="$VARTMP/zpool.cache" zroot
check zpool set bootfs=zroot zroot
check zfs set checksum=fletcher4 zroot

check zfs create zroot/usr
check zfs create zroot/usr/home
check zfs create zroot/var

check zfs create -o compression=on -o exec=on -o setuid=off zroot/tmp
check zfs create -o compression=lzjb -o exec=off -o setuid=off zroot/var/crash
check zfs create -o exec=off -o setuid=off zroot/var/db
check zfs create -o compression=lzjb -o exec=on -o setuid=off zroot/var/db/pkg
check zfs create -o exec=off -o setuid=off zroot/var/empty
check zfs create -o compression=lzjb -o exec=off -o setuid=off zroot/var/log
check zfs create -o compression=gzip -o exec=off -o setuid=off zroot/var/mail
check zfs create -o exec=off -o setuid=off zroot/var/run
check zfs create -o compression=lzjb -o exec=on -o setuid=off zroot/var/tmp

check zfs set mountpoint=/ zroot
check zfs set mountpoint=/tmp zroot/tmp
check zfs set mountpoint=/usr zroot/usr
check zfs set mountpoint=/var zroot/var

check cd "$MNT"
check chmod 1777 tmp
check chmod 1777 var/tmp
check ln -s usr/home home

######################################################################
##                          Part 4: FreeBSD                         ##
######################################################################
echo "4. Installing FreeBSD"

if [ -z $(mount | grep 'tmpfs on /rw/root/sets') ]; then
    check mkdir -p /root/sets
    check mount -t tmpfs -o size=300000000 dummy /root/sets
fi
check cd /root/sets
if [ ! -f base.txz ]; then
    check ftp ftp.FreeBSD.org:/pub/FreeBSD/releases/$ARCH/$ARCH/$FREEBSD_VERSION/base.txz
fi
if [ ! -f kernel.txz ]; then
    check ftp ftp.FreeBSD.org:/pub/FreeBSD/releases/$ARCH/$ARCH/$FREEBSD_VERSION/kernel.txz
fi

check tar --unlink -xpJf base.txz -C "$MNT"
check tar --unlink -xpJf kernel.txz -C "$MNT"

######################################################################
##                           Part 5: Chroot                         ##
######################################################################
echo "5. Configuring FreeBSD"

check cd "$MNT"

echo /dev/label/swap none swap sw 0 0 > etc/fstab
echo 'zfs_load="YES"' > boot/loader.conf
echo 'sshd_enable="YES"' > etc/rc.conf
echo "hostname=\"$HOSTNAME\"" >> etc/rc.conf
echo "defaultrouter=\"$ROUTER\"" >> etc/rc.conf
echo "ifconfig_$INTERFACE=\"$IP\"" >> etc/rc.conf
echo 'zfs_enable="YES"' >> etc/rc.conf
echo 'vfs.root.mountfrom="zfs:zroot"' >> boot/loader.conf
echo 'PermitRootLogin yes' >> etc/ssh/sshd_config

check chroot "$MNT" passwd

echo "Installation done, you can now reboot!"
