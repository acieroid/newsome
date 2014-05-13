#!/bin/sh

# Check the syntax of a service file. As service file are also shell scripts,
# but we don't want to source them to get the variables they define, for
# security reasons, we need to extract ourselves those variables. As we don't
# want to implement a full shell syntax, we restrict the way variables should be
# defined (VAR="value", sticking to the beginning of the line). This script
# checks that a service file correctly defines its variables (at least those we
# need).

if [ "$#" -ne 1 ]; then
    echo "$0: expecting service file in argument"
    exit 1
fi

SERVICE_FILE="$1"

if [ ! -f "$SERVICE_FILE" ]; then
    echo "$SERVICE_FILE does not exist or is not a file"
    exit 1
fi

check_var() {
    if [ -z $(grep -E "^$1=\"[a-zA-Z0-9 \.\-]+\"" "$SERVICE_FILE") ]; then
        echo "$SERVICE_FILE: missing or incorrect declaration of variable $NAME"
        exit 1
    fi
}

check_var NAME
check_var JAIL
check_var LANG
check_var TYPE

# ... that's all for now :]
