#!/bin/sh
NAME="fortune"
JAIL="test"
HOST="home.lan"
TYPE="www"
PORT="8081"
DEPS="git go"

SOURCES="https://github.com/m-b-/fortune.git"
GODEPS=""

build() {
    export GOPATH=`pwd`
    go get ./...
    go build
}

setup() {
    git clone "$SOURCES" "$NAME"
    cd "$NAME"
    build
}

start() {
    cd "$NAME"
    "./$NAME"
}

update() {
    cd "$NAME"
    git pull origin master
    build
}
