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
if [ "$TYPE" = "www-static" -a "$JAIL" != "static" ]; then
    echo "A static website can only be on the 'static' jail, and not on '$JAIL'"
    exit 1
fi

# Create the jail
echo "Creating jail $JAIL"
if [ -d "/usr/jails/$JAIL" ]; then
    SERVICES="$(ls /usr/jails/$JAIL/home/)"
    echo "Jail '$JAIL' already exists and contains the following services:
$SERVICES
This new service will be added in this jail. Enter to continue, ^C to abort"
    read tmp
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

# Install dependencies
LANG=$(extract LANG)
DEPS=$(extract DEPS)

if [ -n "$DEPS" ]; then
    echo "Installing the following dependencies in jail $JAIL: $DEPS"
    ezjail-admin console -e "pkg install -y $DEPS" "$JAIL"
fi

# Configure some service-related stuff (eg. nginx redirection for web services)
case "$TYPE" in
    www|www-static)
        echo "Configuring web service"
        service-configure-type-www.sh "$SERVICE_FILE"
        ;;
    *)
        echo "Service type not (yet) handled: $TYPE"
        ;;
esac

# Copy the service file in the user's directory (inside the jail)
cp "$SERVICE_FILE" "/usr/jails/$JAIL/home/$NAME/$NAME.sh"
jexec "$JAIL" chown "$NAME" "/home/$NAME/$NAME.sh"

# Setup the service
# TODO: output to a log? (to avoid confusion when launching this script)
jexec -U "$NAME" "$JAIL" service-jail-action.sh "/home/$NAME/$NAME.sh" setup

if [ "$TYPE" != "www-static" ]; then
    # Add supervisord stuff to launch it
    echo "[program:$NAME]
command=jexec -U \"$NAME\" \"$JAIL\" service-jail-action.sh \"/home/$NAME/$NAME.sh\" start
stopasgroup=true ; needed to propagate the signal to the actual program
" > "/usr/local/etc/supervisord.d/$NAME.ini"
    supervisorctl reread
fi

# Add to service-manager
mkfifo "/usr/jails/$JAIL/home/$NAME/service.pipe"
if [ -p /root/services.pipe ]; then
    echo "add $JAIL $NAME" > /root/services.pipe
else
    echo "It seems that service-manager is not running. Please launch it and perform the following:"
    echo "echo 'add $JAIL $NAME' > /root/services.pipe"
fi

echo "Service added"
if [ "$TYPE" = "www-static" ]; then
    echo "No need to launch it, it is already handled as it is a static service"
else
    echo "You can launch it with supervisord (supervisorctl start \"$NAME\")"
fi

# TODO: backups
