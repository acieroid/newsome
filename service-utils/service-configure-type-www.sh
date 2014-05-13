#!/bin/sh

if [ "$#" -ne 1 ]; then
    echo "$0: expecting service file in argument"
    exit 1
fi

SERVICE_FILE="$1"

extract() {
    sed -nE "s/^$1=\"(.*)\".*/\1/p" "$SERVICE_FILE" | head -1
}

jail_ip() {
    ezjail-admin list | grep "/usr/jails/$1" | awk '{ print $3 }'
}

NAME="$(extract NAME)"
PORT="$(extract PORT)"
IP="$(jail_ip NAME)"

# TODO: parameter for domain name
echo "server {
    listen 80;
    server_name $NAME.foo.com
    location / {
        proxy_pass http://$IP:$PORT;
    }
}" > "/usr/jails/master/usr/local/etc/nginx/services.d/$NAME.conf"
ezjail-admin console -e "service nginx reload" master
