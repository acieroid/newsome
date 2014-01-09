#!/bin/sh

# This script creates a new slave jail with the name given in
# argument. The local IP will be guessed, but can be given as a second
# argument.

. parameters.sh
. utils.sh

NAME="$1"

if [ -n "$2" ]; then
    LAST="$(cat /etc/rc.conf | grep lo1_alias | sed -E 's/.*inet 172.16.0.([0-9]+) .*/\1/g' | sort -g | tail -1)"
    SUFFIX="$(($LAST+1))"
    IP="172.16.0.$SUFFIX"
else
    IP="$2"
fi

ask "I will create the jail '$NAME' with local IP $IP. Is it OK?" "y"

check ezjail-admin create -f slave "$NAME" "lo1|$IP"
