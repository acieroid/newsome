#!/bin/sh
set -o errexit
set -o nounset

# Minimal post-installation script. Set up pkgng, get newsome and launch the
# real post-installation script.

. ./parameters.sh

# DNS
# TODO: do this in install.sh?
if [ ! -f /etc/resolv.conf ]; then
    echo "nameserver $DNS" > /etc/resolv.conf
fi
if [ -z "$(grep \"$DNS\" /etc/resolv.conf)" ]; then
    echo "nameserver $DNS" > /etc/resolv.conf
fi

# pkgng

# Not needed since FreeBSD 10
if [ -n "$(uname -r | grep '^9\.')" ]; then
    rm /usr/local/etc/pkg.conf
    mkdir -p /usr/local/etc/pkg/repos
    echo 'FreeBSD: {
  url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest",
  mirror_type: "srv",
  enabled: yes
}' > /usr/local/etc/pkg/repos/FreeBSD.conf
fi

pkg update
pkg upgrade

# git
pkg install -y git vim-lite tmux

# get newsome and launch
git clone https://github.com/acieroid/newsome.git
cd newsome/install
tmux new-session "sh launch.sh sh postinst-setup.sh"
