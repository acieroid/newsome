#!/bin/sh

######################################################################
##                             Utils                                ##
######################################################################

ask () {
    QUESTION="$1"
    DEFAULT="$2"
    echo -n "$QUESTION"
    if [ "$DEFAULT" = "y" ]; then
        echo -n " [Y/n] "
    else
        echo -n " [y/N] "
    fi
        
    read ANSWER

    while [ "$ANSWER" != "y" -a "$ANSWER" != "n" ]; do
        echo -n "Please answer y or n: "
        read ANSWER
        if [ "$ANSWER" = "" ]; then
            ANSWER=DEFAULT
        fi
    done
}

fail_if_no () {
    ask "$1" "$2"
    if [ "$ANSWER" = "n" ]; then
        exit 1
    fi
}    

check () {
    CMD="$@"
    echo "$CMD"
    $CMD
    if [ "$?" != 0 ]; then
        echo "ERROR: command $CMD failed, stopping"
        exit 1
    fi
    if [ "$DEBUG" = "YES" ]; then
        echo "done, press enter to continue"
        read foo
    fi
}

check_prev () {
    CMD="$@"
    if [ "$?" != 0 ]; then
        echo "ERROR: command $CMD failed, stopping"
        exit 1
    fi
}
