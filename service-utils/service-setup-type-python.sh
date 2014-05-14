#!/bin/sh

# Setup a python service from within the service jail, given the absolute path
# to the service file

if [ "$#" -ne 1 ]; then
    echo "$0: expecting service file in argument"
    exit 1
fi

SERVICE_FILE="$1"

if [ ! -f "$SERVICE_FILE" ]; then
    echo "$SERVICE_FILE does not exist"
    exit 1
fi

extract() {
    sed -nE "s/^$1=\"(.*)\".*/\1/p" "$SERVICE_FILE" | head -1
}

NAME="$(extract NAME)"
su - "$NAME" # TODO: cannot su

if [ ! -f "$SERVICE_FILE" ]; then
    echo "$SERVICE_FILE is not an absolute path (and I really need one)"
    exit 1
fi

# TODO: don't rerun this if it has already been done

virtualenv virtualenv
. virtualenv/bin/activate
. "$SERVICE_FILE"
pip install "$PYTHON_DEPS"
setup()
