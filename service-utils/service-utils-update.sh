#!/bin/sh
set -o errexit
set -o nounset

# Copy service-utils files to the bin directory of every user's bin/ directory
# in the given jail. Expects the jail as argument, and the service-utils files
# to be present in /root/bin.

if [ "$#" -ne 1 ]; then
    echo "$0: expecting jail in argument"
    exit 1
fi

JAIL="$1"

if [ ! -d "/usr/jails/$JAIL" ]; then
    echo "Cannot update service-util in jail '$JAIL', the jail doesn't exist."
    exit 1
fi

if [ -d "/usr/jails/$JAIL/home" ]; then
    find "/usr/jails/$JAIL/home" -maxdepth 1 -exec \
        cp -f /root/bin/service-jail-action.sh "{}/bin" \;
fi
