#!/bin/sh
set -o errexit
set -o nounset

# This script creates and setup the jail, user account, dependencies and
# everything necessary for a particular service to run. It must be launched on
# the host.

if [ "$#" -ne 1 ]; then
    echo "$0: expecting service file in argument"
    exit 1
fi

SERVICE_FILE="$1"

extract() {
    sed -nE "/^$1/{s/^$1=\"(.*)\".*/\1/p;q;}" "$SERVICE_FILE"
}

# Check that the service file does not contain incorrect or malicious stuff
service-check-syntax.sh "$SERVICE_FILE"
if [ "$?" -ne 0 ]; then
    echo "Cannot continue, syntax of '$SERVICE_FILE' is invalid"
    exit 1
fi

# A static website can only be on the "static" jail
TYPE=$(extract TYPE)
JAIL=$(extract JAIL)
if [ "$TYPE" = "www-static" && "$JAIL" != "static" ]; then
    echo "A static website can only be on the 'static' jail, and not on '$JAIL'"
    exit 1
fi

# Create the jail
echo "Creating jail $JAIL"
if [ -d "/usr/jails/$JAIL" ]; then
    SERVICES="$(ls /usr/jails/$JAIL/home/)"
    echo "Jail '$JAIL' already exists and contains the following services:
$SERVICES
Is it OK to add this service to this jail? [y/N]"
    read ANSWER
    if [ "$ANSWER" != "y" -o "$ANSWER" != "Y" ]; then
        echo "Not adding the service to a currently existing jail"
        exit 1
    fi
fi

service-create-jail.sh "$JAIL"
if [ "$?" -ne 0 ]; then
    echo "Error when creating jail $JAIL"
    exit 1
fi

# Add the service's user to the jail
NAME=$(extract NAME)
echo "Creating user $NAME in jail $JAIL"
service-create-user.sh "$JAIL" "$NAME"
if [ "$?" -ne 0 ]; then
    echo "Error when creating user $NAME"
    exit 1
fi

# Install needed shell scripts to the user inside the jail
echo "Installing service-utils for user '$NAME' in jail '$JAIL'"
service-utils-install.sh "$JAIL" "$NAME"
if [ "$?" -ne 0 ]; then
    echo "Error when installing service-utils for user '$NAME' in jail '$JAIL'"
    exit 1
fi

# Install dependencies
LANG=$(extract LANG)
DEPS=$(extract DEPS)

if [ -n "$DEPS" ]; then
    echo "Installing the following dependencies in jail $JAIL: $DEPS"
    ezjail-admin console -e "pkg install -y $DEPS" "$JAIL"
fi

# Configure some service-related stuff (eg. nginx redirection for web services)
case "$TYPE" in
    www)
    www-static)
        echo "Configuring web service"
        service-configure-type-www.sh "$SERVICE_FILE"
        ;;
    *)
        echo "Service type not (yet) handled: $TYPE"
        ;;
esac

# Copy the service file in the user's directory (inside the jail)
SERVICE=$(basename "$SERVICE_FILE")
cp "$SERVICE_FILE" "/usr/jails/$JAIL/home/$NAME/"

# Setup the service
jexec -U "$NAME" "$JAIL" service-jail-action.sh "/home/$NAME/services/$SERVICE" setup

# Add supervisord stuff to launch it
echo "[program:$NAME]
command=jexec -U \"$NAME\" \"$JAIL\" service-jail-action.sh \"/home/$NAME/services/$SERVICE\" start
stopasgroup=true ; needed to propagate the signal to the actual program
" > "/usr/local/etc/supervisord.d/$NAME.ini"
supervisorctl reread

# Add to service-manager
mkfifo "/usr/jails/$JAIL/home/$NAME/service.pipe"
if [ -p /root/services.pipe ]; then
    echo "add $JAIL $NAME" > /root/services.pipe
else
    echo "It seems that service-manager is not running. Please launch it and perform the following:"
    echo "echo 'add $JAIL $NAME' > /root/services.pipe"
else

echo "Service added, you can launch it with supervisord (supervisorctl start \"$NAME\")"

# TODO: backups
