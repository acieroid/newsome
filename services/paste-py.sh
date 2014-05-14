#!/bin/sh

## Meta

# Name of the service
NAME="paste"
# Jail on which the service is installed
JAIL="test"
# Language used by this service (will influence the way it is installed)
LANG="python"
# Host which will host this service (on $NAME.$HOST)
HOST="foo.com"
# Category of the service
TYPE="www"
# On which port to connect
PORT="8000"
# Dependencies (other than language)
DEPS="git"
# Python dependencies (installed with pip in a virtualenv)
PYTHON_DEPS="Pygments tornado"
# Sources
SOURCES="https://github.com/acieroid/paste-py.git"

## Functions

# How to setup the program the first time
setup() {
    git clone "$SOURCES" paste-py
}

# How to launch the program
start() {
    cd paste-py
    python paste.py
}

# How to check if the program is correctly running
alive() {
    ANSWER="$(curl --head "$WWW_URL" | head -1)"
    if [  = "HTTP/1.1 200 OK"]; then
        ALIVE="YES"
    else
        ALIVE="NO"
        REASON="$ANSWER"
    fi
}
