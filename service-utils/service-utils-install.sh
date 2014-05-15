#!/bin/sh
set -o errexit
set -o nounset

# Copy service-utils files to the bin directory of a service's user in the given
# jail. Expects the jail and user name as argument, and the service-utils files
# to be present in /root/bin.

if [ "$#" -ne 2 ]; then
    echo "$0: expecting jail and user in argument"
    exit 1
fi

JAIL="$1"
USER="$2"

if [ ! -d "/usr/jails/$JAIL/home/$USER" ]; then
    echo "Cannot install service-util for user '$USER' in jail '$JAIL', \
the jail or the user doesn't exist."
    exit 1
fi

mkdir -p "/usr/jails/$JAIL/home/$USER/bin"
cp /root/bin/service-jail-action.sh "/usr/jails/$JAIL/home/$USER/bin"
