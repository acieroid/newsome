#!/bin/sh

# This script performs the post-installation configuration on a clean
# FreeBSD.

. parameters.sh
. utils.sh

######################################################################
##                  Post installation configuration                 ##
######################################################################

echo "Configuring DNS"
echo "nameserver $DNS" > /etc/resolv.conf

echo "Configuring pkgng. Answer 'y' when asked something"
rm /usr/local/etc/pkg.conf
mkdir -p /usr/local/etc/pkg/repos
echo 'FreeBSD: {
  url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest",
  mirror_type: "srv",
  enabled: yes
}' > /usr/local/etc/pkg/repos/FreeBSD.conf

pkg
pkg update
pkg upgrade

echo "Done."
