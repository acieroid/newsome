#!/bin/sh

## Meta

# Name of the service
NAME="paste"
# Jail on which the service is installed
JAIL="test"
# Host which will host this service (on $NAME.$HOST)
HOST="foo.com"
# Category of the service
TYPE="www"
# On which port to connect
PORT="8000"
# Dependencies
DEPS="python27 py27-virtualenv py27-pip git"

## Variables used in this script

# Python dependencies (installed with pip in a virtualenv)
PYTHON_DEPS="Pygments tornado"
# Sources
SOURCES="https://github.com/acieroid/paste-py.git"

## Functions

# How to setup the program the first time
setup() {
    virtualenv virtualenv
    . virtualenv/bin/activate
    pip install $PYTHON_DEPS
    git clone "$SOURCES" paste-py
}

# How to launch the program
start() {
    . virtualenv/bin/activate
    cd paste-py
    python paste.py --port="$PORT"
}

# How to update the program
update() {
  cd paste-py
  git pull origin master
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
