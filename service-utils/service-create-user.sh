#!/bin/sh

# Create an user (second argument) in the given jail (first argument), only if
# the user does not already exist. If the user already exists, this script
# does nothing (and fails).

if [ "$#" -ne 2 ]; then
    echo "$0: expecting jail and user name in argument"
    exit 1
fi

JAIL="$1"
USER="$2"

if [ ! -d "/usr/jails/$JAIL" ]; then
    echo "Cannot create user in jail '$JAIL', this jail does not exist"
    exit 1
fi

if [ -d "/usr/jails/$JAIL/home/$USER" ]; then
    echo "Cannot create user '$USER' in jail '$JAIL', this user already exists"
    exit 1
fi

ezjail-admin console -e "pw user add '$USER' -m -d '/home/$USER' -G service"
