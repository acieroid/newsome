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
GOPATH=`pwd`/gopath

build() {
    # Go dependencies
    go get ./...
    go build
}

setup() {
    if [ ! -d "$GOPATH" ]; then
	    mkdir $GOPATH
    fi
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
