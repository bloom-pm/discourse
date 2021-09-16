#!/bin/bash

nc -w 1 app 3000

while [ $? -eq 1 ]; do
  sleep 1
  echo "Retrying to check port on ruby app"
  nc -w 1 app 3000
done

mkdir -p /etc/nginx/conf.d  
mkdir -p /usr/share/nginx
mkdir -p /var/www/discourse/public
envsubst '$DISCOURSE_HOST' < /etc/nginx/site.conf.t > /etc/nginx/conf.d/default.conf 
exec nginx -g 'daemon off;'