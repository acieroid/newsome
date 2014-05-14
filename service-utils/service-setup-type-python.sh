#!/bin/sh

# Setup a service from within the service jail, given the absolute path
# to the service file. This has to be launched from the service's user.

if [ "$#" -ne 1 ]; then
    echo "$0: expecting service file in argument"
    exit 1
fi

SERVICE_FILE="$1"

if [ ! -f "$SERVICE_FILE" ]; then
    echo "$SERVICE_FILE is not an absolute path (and I really need one)"
    exit 1
fi

. "$SERVICE_FILE"
cd "/home/$NAME"
setup()
