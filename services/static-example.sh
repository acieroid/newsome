#!/bin/sh

NAME="static-example"
JAIL="static"
HOST="foo.com"
TYPE="www-static"
PORT="0"
DEPS=""

ARCHIVE="IA.tar.gz"
SOURCE="http://awesom.eu/~acieroid/$ARCHIVE"

setup() {
    fetch "$SOURCE"
    tar xvf "$ARCHIVE"
    mv IA www
}

update() {
    setup
}
