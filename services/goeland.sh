NAME="goeland"
JAIL="test"
HOST="foo.com"
TYPE="www"
PORT="8000"
DEPS="git go"

SOURCES="https://github.com/acieroid/goeland.git"
GODEPS="github.com/kuroneko/gosqlite3"

build() {
    export GOPATH=`pwd`
    for dep in $GODEPS; do
        go get "$dep"
    done
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
