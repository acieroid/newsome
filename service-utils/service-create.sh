#!/bin/sh

# This script creates and setup the jail, user account, dependencies and
# everything necessary for a particular service to run. It must be launched on
# the host.

if [ "$#" -ne 1 ]; then
    echo "$0: expecting service file in argument"
    exit 1
fi

SERVICE_FILE="$1"

extract() {
    sed -nE "s/^$1=\"(.*)\".*/\1/p" "$SERVICE_FILE" | head -1
}

service-check-syntax.sh "$SERVICE_FILE"
if [ "$?" -ne 0 ]; then
    echo "Cannot continue, syntax of '$SERVICE_FILE' is invalid"
    exit 1
fi

JAIL=$(extract JAIL)
echo "Creating jail $JAIL"
service-create-jail.sh "$JAIL"
if [ "$?" -ne 0 ]; then
    echo "Error when creating jail $JAIL"
    exit 1
fi

NAME=$(extract NAME)
echo "Creating user $NAME in jail $JAIL"
service-create-user.sh "$JAIL" "$NAME"
if [ "$?" -ne 0 ]; then
    echo "Error when creating user $NAME"
    exit 1
fi

LANG=$(extract LANG)
TYPE=$(extract TYPE)
DEPS=$(extract DEPS)

echo "Installing the following dependencies in jail $JAIL: $DEPS"
ezjail-admin console -e "pkg install -y '$DEPS'" "$JAIL"

case "$TYPE" in
    www)
        echo "Configuring web service"
        service-configure-type-www.sh "$SERVICE_FILE"
        ;;
    *)
        echo "Service type not (yet) handled: $TYPE"
        ;;
esac

case "$LANG" in
    python)
        echo "Configuring python service"
        service-configure-lang-python.sh "$SERVICE_FILE"
        ;;
    *)
        echo "Service language not (yet) handled: $LANG"
        ;;
esac

SERVICE=$(basename "$SERVICE_FILE")
cp "$SERVICE_FILE" "/root/services/$SERVICE"

echo "[program:$NAME]
command=service-launch.sh /root/services/$SERVICE
" > "/usr/local/etc/supervisor.d/$NAME.conf"

# TODO: backups
