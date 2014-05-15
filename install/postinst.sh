#!/bin/sh
set -o errexit
set -o nounset

# Minimal post-installation script. Set up pkgng, get newsome and launch the
# real post-installation script.

# DNS
echo 'nameserver 8.8.8.8' > /etc/resolv.conf

# pkgng

# Not needed since FreeBSD 10 (maybe even 9.2 ?)
# rm /usr/local/etc/pkg.conf
# mkdir -p /usr/local/etc/pkg/repos
# echo 'FreeBSD: {
#   url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest",
#   mirror_type: "srv",
#   enabled: yes
# }' > /usr/local/etc/pkg/repos/FreeBSD.conf

pkg update
pkg upgrade

# git
pkg install -y git

# get newsome and launch
git clone https://github.com/acieroid/newsome.git
cd newsome/install
sh postinst-setup.sh
