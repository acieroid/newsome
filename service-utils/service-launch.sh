#!/bin/sh
set -o errexit
set -o nounset

# This script launches a service. It has to be called from supervisord, and does
# not return (it is completely handled by supervisord)

if [ "$#" -ne 1 ]; then
    echo "$0: expecting service file in argument"
    exit 1
fi

SERVICE_FILE="$1"

extract() {
    sed -nE "/^$1/{s/^$1=\"(.*)\".*/\1/p;q;}" "$SERVICE_FILE"
}

service-check-syntax.sh "$SERVICE_FILE"
if [ "$?" -ne 0 ]; then
    echo "Cannot continue, syntax of '$SERVICE_FILE' is invalid"
    exit 1
fi

JAIL=$(extract JAIL)
NAME=$(extract NAME)

jexec -U "$NAME" "$JAIL" service-jail-action.sh "/home/$NAME/$SERVICE" start
