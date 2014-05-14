#!/bin/sh

# Set up a jail for a python service

if [ "$#" -ne 1 ]; then
    echo "$0: expectnig service file in argument"
    exit 1
fi

SERVICE_FILE="$1"

extract() {
    sed -nE "s/^$1=\"(.*)\".*/\1/p" "$SERVICE_FILE" | head -1
}

JAIL=$(extract JAIL)
NAME=$(extract NAME)
SERVICE=$(basename $SERVICE_FILE)

ezjail-admin console -e "pkg install -y python27 py27-virtualenv py27-pip" "$JAIL"
mkdir -p "/usr/jails/$JAIL/root/services/"
cp "$SERVICE_FILE" "/usr/jails/$JAIL/root/services/$SERVICE"
