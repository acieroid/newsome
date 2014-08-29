#!/bin/sh

NAME="static-example"
JAIL="static"
HOST="foo.com"
TYPE="www-static"
DEPS=""

ARCHIVE="IA.tar.gz"
SOURCE="http://awesom.eu/~acieroid/$ARCHIVE"

setup() {
    wget "$SOURCE"
    tar xvf "$ARCHIVE"
}

update() {
    setup()
}
