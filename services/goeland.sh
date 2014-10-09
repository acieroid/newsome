NAME="goeland"
JAIL="test"
HOST="foo.com"
TYPE="www"
PORT="8000"
DEPS="git go"

SOURCES="https://github.com/acieroid/goeland.git"

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
