NAME="go-example"
JAIL="test"
HOST="foo.com"
TYPE="www"
PORT="9001"
DEPS="git go"

# either git clone $SOURCES or go get it
SOURCES="https://github.com/acieroid/goeland.git"

# One GOPATH per project, to reduce permissions, dependencies issues
# at a higher storage cost.
export GOPATH=`pwd`/gopath

build() {
    # Go dependencies
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
