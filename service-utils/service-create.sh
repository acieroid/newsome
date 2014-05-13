#!/bin/sh

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

JAIL="$(extract JAIL)"
service-create-jail.sh "$JAIL"
if [ "$?" -ne 0 ]; then
    echo "Error when creating jail $JAIL"
    exit 1
fi

NAME="$(extract NAME)"
service-create-user.sh "$JAIL" "$NAME"
if [ "?" -ne 0 ]; then
    echo "Error when creating user $NAME"
    exit 1
fi

LANG="$(extract LANG)"
TYPE="$(extract TYPE)"

case "$TYPE" in
    www)
        service-configure-type-www.sh "$SERVICE_FILE"
        ;;
    *)
        echo "Service type not (yet) handled: $TYPE"
        ;;
esac

case "$LANG" in
    python)
        service-configure-lang-python.sh "$SERVICE_FILE"
        ;;
    *)
        echo "Service language not (yet) handled: $LANG"
        ;;
esac

# TODO: other non-language related stuff (eg. backups)
