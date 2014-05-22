#!/bin/sh
set -o errexit
set -o nounset

# This script updates all the jails' service-util installation. It does so by
# copying the current version of the shell files needed by the jails in every
# jail's /home/*/bin directories

ezjail-admin list | \
    awk '/usr\/jails/{ system("service-utils-update.sh " $4) }'
