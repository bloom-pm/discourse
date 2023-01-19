FROM nginx

COPY nginx.conf /etc/nginx/nginx.conf

COPY site.conf.t /etc/nginx/site.conf.t

COPY nginx.sh /etc/nginx/nginx.sh

RUN chmod +x /etc/nginx/nginx.sh

RUN mkdir -p /var/nginx/cache

RUN chmod 0777 /var/nginx/cache

RUN apt-get update

RUN apt-get install dnsutils netcat vim -y