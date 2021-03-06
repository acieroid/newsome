#!/bin/sh
set -o errexit
set -o nounset

# Create the jail for a service, if it does not already exist. The jail name
# should be given in argument.

if [ "$#" -ne 1 ]; then
    echo "$0: expecting jail name in argument"
    exit 1
fi

JAIL="$1"

if [ -d "/usr/jails/$JAIL" ]; then
    echo "Not creating jail '$JAIL', it already exists."
    exit 0
fi

next_ip() {
    IP=$(ezjail-admin list | awk '/172/ { print $3 }' | sort -g | tail -1)
    FIRSTBYTES=$(echo "$IP" | cut -d. -f1-2)
    LASTBYTE=$(echo "$IP" | cut -d. -f4)
    BEFORETOLASTBYTE=$(echo "$IP" | cut -d. -f3)
    if [ "$LASTBYTE" -eq "255" ]; then
        BTL=$(echo "$BEFORETOLASTBYTE 1 + p" | dc)
        echo "$FIRSTBYTES.$BTL.1"
    else
        L=$(echo "$LASTBYTE 1 + p" | dc)
        echo "$FIRSTBYTES.$BEFORETOLASTBYTE.$L"
    fi
}

IP=$(next_ip)

echo "Creating jail '$JAIL' with IP '$IP'"
ezjail-admin create -f slave "$JAIL" "lo1|$IP"
ezjail-admin start "$JAIL"
ezjail-admin console -e "pkg update" "$JAIL"
ezjail-admin console -e "pw group add service" "$JAIL"
mkdir -p "/usr/jails/$JAIL/usr/local/bin/"
cp /root/bin/service-jail-action.sh "/usr/jails/$JAIL/usr/local/bin/"
