#!/bin/sh
set -o errexit
set -o nounset

# Do some action for a service from within the service's jail, given the
# absolute path to the service file. This has to be launched from the service's
# user.

if [ "$#" -ne 2 ]; then
    echo "$0: expecting service file and action in argument"
    exit 1
fi

SERVICE_FILE="$1"
ACTION="$2"

if [ ! -f "$SERVICE_FILE" ]; then
    echo "$SERVICE_FILE is not an absolute path (and I really need one)"
    exit 1
fi

. "$SERVICE_FILE"
cd "/home/$NAME"

case "$ACTION" in
    start)
        start()
        ;;
    update)
        update()
        ;;
    setup)
        setup()
        ;;
    *)
        echo "Unknown action: $ACTION"
        exit 1
esac
