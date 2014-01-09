#!/bin/sh

# This script performs a clean install of FreeBSD, using ZFS. It can
# be run on a mfsBSD or on a kimsufi in FreeBSD rescue mode for
# example.

# IMPORTANT: adapt the parameters below before launching it

######################################################################
##                          Parameters                              ##
######################################################################

# The installation will completely wipe out the content of this disk
DISK="ada0"

# The machine's hostname
# On a kimsufi, set it to your kimsufi's name (ks123456.kimsufi.com)
HOSTNAME="foo"

# The name of the ethernet interface
# Do `ifconfig` or `ip link` to find it
INTERFACE="rl0"

# Static IP address
# Set to DHCP to have a dynamic one
# On a kimsufi, look at your current IP (`ifconfig` or `ip addr`)
IP="inet 192.168.2.110 netmask 255.255.255.0 broadcast 192.168.2.255"

# Address of the router
# Generally the /24 of your IP followed by .1
# On a kimsufi, the /24 of your IP followed by .254
ROUTER="192.168.2.1"

# Size of the swap partition
# Depends on the usage. Generally 2 times the RAM size is good.
# On a kimsufi, 4G is fine
SWAPSIZE="1G"

# FreeBSD version
FREEBSD_VERSION="9.2-RELEASE"

# Architecture
ARCH="$(uname -m)"

######################################################################
##                             Utils                                ##
######################################################################

DEBUG="NO"

fail_if_no () {
    read ANSWER

    while [ "$ANSWER" != "y" -a "$ANSWER" != "n" ]; do
        echo -n "Please answer y or n: "
        read ANSWER
        if [ "$ANSWER" = "" ]; then
            ANSWER="n"
        fi
    done
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
    echo -n "WARNING: this script should be run as root (and it is \
not). Are you sure you want to continue? [y/N]"
    fail_if_no
fi

gpart list "$DISK" > /dev/null
if [ "$?" -ne 0 ]; then
    echo -n "WARNING: the following disk does not exist: \
$DISK. Are you sure you want to continue? [y/N]"
    fail_if_no
fi

echo -n "WARNING: this script will erase everything present on the \
following drive: $DISK. Are you OK with that? [y/N] "
fail_if_no

ifconfig "$INTERFACE" > /dev/null
if [ "$?" -ne 0 ]; then
    echo -n "WARNING: the following interface does not exist: \
$INTERFACE. Are you sure you want to continue? [y/N]"
    fail_if_no
fi

echo -n "Please review the following configuration carefully:
    DISK=\"$DISK\"
    HOSTNAME=\"$HOSTNAME\"
    INTERFACE=\"$INTERFACE\"
    IP=\"$IP\"
    ROUTER=\"$ROUTER\"
    SWAPSIZE=\"$SWAPSIZE\"
    FREEBSD_VERSION=\"$FREEBSD_VERSION\"
    ARCH=\"$ARCH\"
If everything is OK, the script will start the installation.
OK? [y/N]"
fail_if_no

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

check zpool create -f -o altroot=/mnt -o cachefile=/var/tmp/zpool.cache zroot /dev/gpt/data
check zpool export zroot
check zpool import -o altroot=/mnt -o cachefile=/var/tmp/zpool.cache zroot
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

check cd /mnt/
check chmod 1777 tmp
check chmod 1777 var/tmp
check ln -s usr/home home

######################################################################
##                          Part 4: FreeBSD                         ##
######################################################################
echo "4. Installing FreeBSD"

check mkdir -p /root/sets
check mount -t tmpfs -o size=300000000 dummy /root/sets
check cd /root/sets
check ftp ftp.FreeBSD.org:/pub/FreeBSD/releases/amd64/amd64/9.2-RELEASE/base.txz
check ftp ftp.FreeBSD.org:/pub/FreeBSD/releases/amd64/amd64/9.2-RELEASE/kernel.txz

echo "cat base.txz | tar --unlink -xpJf - -C /mnt/"
cat base.txz | tar --unlink -xpJf - -C /mnt/
check_prev
echo "cat kernel.txz | tar --unlink -xpJf - -C /mnt/"
cat kernel.txz | tar --unlink -xpJf - -C /mnt/
check_prev

######################################################################
##                           Part 5: Chroot                         ##
######################################################################
echo "5. Configuring FreeBSD"

check cd /mnt/

echo /dev/label/swap none swap sw 0 0 > etc/fstab
echo 'zfs_load="YES"' > boot/loader.conf
echo 'sshd_enable="YES"' > etc/rc.conf
echo "hostname=\"$HOSTNAME\"" >> etc/rc.conf
echo "defaultrouter=\"$ROUTER\"" >> etc/rc.conf
echo "ifconfig_$INTERFACE=\"$IP\"" >> etc/rc.conf
echo 'zfs_enable="YES"' >> etc/rc.conf
echo 'vfs.root.mountfrom="zfs:zroot"' >> boot/loader.conf
echo 'PermitRootLogin yes' >> etc/ssh/sshd_config

check chroot /mnt/ passwd

echo "Installation done, you can now reboot!"
