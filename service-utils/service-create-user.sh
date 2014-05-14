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

if [ -z $(echo "$USER" | grep -E "^[a-zA-Z0-9\.\-]+$") ]; then
    echo "Cannot  create user '$USER' in jail '$JAIL': invalid user name"
    exit 1
fi

if [ ! -d "/usr/jails/$JAIL" ]; then
    echo "Cannot create user in jail '$JAIL': jail does not exist"
    exit 1
fi

if [ ! -z "$(grep -E "^$USER:" "/usr/jails/$JAIL/etc/passwd")" ]; then
    echo "Cannot create user '$USER' in jail '$JAIL': user already exists"
    exit 1
fi

echo "Creating user '$USER' in jail '$JAIL'"
ezjail-admin console -e "pw user add $USER -m -d /home/$USER -G service" "$JAIL"
