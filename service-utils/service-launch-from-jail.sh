#!/bin/sh

# This script launches a service from within its jail. It has to be run by the
# service's user, and it does not return.

if [ "$#" -ne 1 ]; then
    echo "$0: expecting service file in argument"
    exit 1
fi

SERVICE_FILE="$1"

. "$SERVICE_FILE"
cd "/home/$NAME"
start()
