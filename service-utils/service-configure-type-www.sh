#!/bin/sh
set -o errexit
set -o nounset

if [ "$#" -ne 1 ]; then
    echo "$0: expecting service file in argument"
    exit 1
fi

SERVICE_FILE="$1"

extract() {
    sed -nE "/^$1/{s/^$1=\"(.*)\".*/\1/p;q;}" "$SERVICE_FILE"
}

jail_ip() {
    ezjail-admin list | grep "/usr/jails/$1" | awk '{ print $3 }'
}

NAME=$(extract NAME)
PORT=$(extract PORT)
HOST=$(extract HOST)
JAIL=$(extract JAIL)
TYPE=$(extract TYPE)
IP=$(jail_ip $JAIL)

case "$TYPE" in
    www)
        echo "Adding redirection on $NAME.$HOST to $IP:$PORT"
        mkdir -p /usr/jails/master/usr/local/etc/nginx/services.d/
        echo "server {
    listen 80;
    server_name $NAME.$HOST;
    location / {
        proxy_set_header Host \$host;
        proxy_pass http://$IP:$PORT;
    }
}" > "/usr/jails/master/usr/local/etc/nginx/services.d/$NAME.conf"
        ;;
    www-static)
        echo "Adding static website configuration to nginx"
        mkdir -p /usr/jails/static/usr/local/etc/nginx/services.d/
        echo "server {
    listen 80;
    server_name $NAME.$HOST;
    location / {
        root /home/$NAME/www/;
    }
}" > "/usr/jails/static/usr/local/etc/nginx/services.d/$NAME.conf"
        echo "Adding redirection on $NAME.$HOST to this static website"
        mkdir -p /usr/jails/master/usr/local/etc/nginx/services.d/
        echo "server {
    listen 80;
    server_name $NAME.$HOST;
    location / {
        proxy_set_header Host \$host;
        proxy_pass http://$IP:80;
    }
}" > "/usr/jails/master/usr/local/etc/nginx/services.d/$NAME.conf"
        ezjail-admin console -e "service nginx reload" static
        ;;
esac

ezjail-admin console -e "service nginx reload" master
