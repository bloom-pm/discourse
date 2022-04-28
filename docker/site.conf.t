# Additional MIME types that you'd like nginx to handle go in here
types {
    text/csv csv;
    application/wasm wasm;
}



# inactive means we keep stuff around for 1440m minutes regardless of last access (1 week)
# levels means it is a 2 deep hierarchy cause we can have lots of files
# max_size limits the size of the cache
proxy_cache_path /var/nginx/cache inactive=1440m levels=1:2 keys_zone=one:10m max_size=600m;

# see: https://meta.discourse.org/t/x/74060
proxy_buffer_size 8k;

# If you are going to use Puma, use these:
#
# upstream discourse {
#   server unix:/var/www/discourse/tmp/sockets/puma.sock;
# }


# attempt to preserve the proto, must be in http context
map $http_x_forwarded_proto $thescheme {
  default $scheme;
  https https;
}

log_format log_discourse '[$time_local] "$http_host" $remote_addr "$request" "$http_user_agent" "$sent_http_x_discourse_route" $status $bytes_sent "$http_referer" $upstream_response_time $request_time "$upstream_http_x_discourse_username" "$upstream_http_x_discourse_trackview" "$upstream_http_x_queue_time" "$upstream_http_x_redis_calls" "$upstream_http_x_redis_time" "$upstream_http_x_sql_calls" "$upstream_http_x_sql_time"';

# Allow bypass cache from localhost
geo $bypass_cache {
  default         0;
  127.0.0.1       1;
  ::1             1;
}

server {

  resolver 127.0.0.11 valid=30s;

  set $upstream localhost:3000;

  access_log /var/log/nginx/access.log log_discourse;

  listen 80;
  gzip on;
  gzip_vary on;
  gzip_min_length 1000;
  gzip_comp_level 5;
  gzip_types application/json text/css text/javascript application/x-javascript application/javascript image/svg+xml application/wasm;
  gzip_proxied any;

  # Uncomment and configure this section for HTTPS support
  # NOTE: Put your ssl cert in your main nginx config directory (/etc/nginx)
  #
  # rewrite ^/(.*) https://enter.your.web.hostname.here/$1 permanent;
  #
  # listen 443 ssl;
  # ssl_certificate your-hostname-cert.pem;
  # ssl_certificate_key your-hostname-cert.key;
  # ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  # ssl_ciphers HIGH:!aNULL:!MD5;
  #

  server_name _;
  server_tokens off;

  sendfile on;

  keepalive_timeout 65;

  # maximum file upload size (keep up to date when changing the corresponding site setting)
  client_max_body_size 10m;

  # path to discourse's public directory
  set $public /var/www/discourse/public;

  # without weak etags we get zero benefit from etags on dynamically compressed content
  # further more etags are based on the file in nginx not sha of data
  # use dates, it solves the problem fine even cross server
  etag off;

  # prevent direct download of backups
  location ^~ /backups/ {
    internal;
  }


  location / {
    root $public;
    add_header ETag "";

    # auth_basic on;
    # auth_basic_user_file /etc/nginx/htpasswd;

    location ~ ^/uploads/short-url/ {
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Request-Start "t=${msec}";
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $thescheme;
      proxy_pass http://$upstream;
      break;
    }

    location ~ ^/secure-media-uploads/ {
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Request-Start "t=${msec}";
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $thescheme;
      proxy_pass http://$upstream;
      break;
    }

    location ~* (fonts|assets|plugins|uploads)/.*\.(eot|ttf|woff|woff2|ico|otf)$ {
      expires 1y;
      add_header Cache-Control public,immutable;
      add_header Access-Control-Allow-Origin *;
    }

    location = /srv/status {
      access_log off;
      log_not_found off;
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Request-Start "t=${msec}";
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $thescheme;
      proxy_pass http://$upstream;
      break;
    }

    # some minimal caching here so we don't keep asking
    # longer term we should increase probably to 1y
    location ~ ^/javascripts/ {
      expires 1d;
      add_header Cache-Control public,immutable;
      add_header Access-Control-Allow-Origin *;
    }

    location ~ ^/assets/(?<asset_path>.+)$ {
      expires 1y;
      # asset pipeline enables this
      #brotli_static on;
      gzip_static on;
      add_header Cache-Control public,immutable;
      # HOOK in asset location (used for extensibility)
      # TODO I don't think this break is needed, it just breaks out of rewrite
      break;
    }

    location ~ ^/plugins/ {
      expires 1y;
      add_header Cache-Control public,immutable;
      add_header Access-Control-Allow-Origin *;
    }

    # cache emojis
    location ~ /images/emoji/ {
      expires 1y;
      add_header Cache-Control public,immutable;
      add_header Access-Control-Allow-Origin *;
    }

    location ~ ^/uploads/ {

      # NOTE: it is really annoying that we can't just define headers
      # at the top level and inherit.
      #
      # proxy_set_header DOES NOT inherit, by design, we must repeat it,
      # otherwise headers are not set correctly
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Request-Start "t=${msec}";
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $thescheme;
      proxy_set_header X-Sendfile-Type X-Accel-Redirect;
      proxy_set_header X-Accel-Mapping $public/=/downloads/;
      expires 1y;
      add_header Cache-Control public,immutable;

      ## optional upload anti-hotlinking rules
      #valid_referers none blocked mysite.com *.mysite.com;
      #if ($invalid_referer) { return 403; }

      # custom CSS
      location ~ /stylesheet-cache/ {
          add_header Access-Control-Allow-Origin *;
          try_files $uri =404;
      }
      # this allows us to bypass rails
      location ~* \.(gif|png|jpg|jpeg|bmp|tif|tiff|ico|webp)$ {
          add_header Access-Control-Allow-Origin *;
          try_files $uri =404;
      }
      # SVG needs an extra header attached
      location ~* \.(svg)$ {
      }
      # thumbnails & optimized images
      location ~ /_?optimized/ {
          add_header Access-Control-Allow-Origin *;
          try_files $uri =404;
      }

      try_files $uri @discourse;
      break;
    }

    location ~ ^/admin/backups/ {
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Request-Start "t=${msec}";
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $thescheme;
      proxy_set_header X-Sendfile-Type X-Accel-Redirect;
      #proxy_set_header X-Accel-Mapping $public/=/downloads/;
      proxy_pass http://$upstream;
      break;
    }

    # This big block is needed so we can selectively enable
    # acceleration for backups, avatars, sprites and so on.
    # see note about repetition above
    location ~ ^/(svg-sprite/|letter_avatar/|letter_avatar_proxy/|user_avatar|highlight-js|stylesheets|theme-javascripts|favicon/proxied|service-worker) {
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Request-Start "t=${msec}";
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $thescheme;

      # if Set-Cookie is in the response nothing gets cached
      # this is double bad cause we are not passing last modified in
      proxy_ignore_headers "Set-Cookie";
      proxy_hide_header "Set-Cookie";
      proxy_hide_header "X-Discourse-Username";
      proxy_hide_header "X-Runtime";

      # note x-accel-redirect can not be used with proxy_cache
      proxy_cache one;
      proxy_cache_key "$scheme,$host,$request_uri";
      proxy_cache_valid 200 301 302 7d;
      proxy_cache_valid any 1m;
      proxy_cache_bypass $bypass_cache;
      proxy_pass http://$upstream;
      break;
    }

    # we need buffering off for message bus
    location /message-bus/ {
      proxy_set_header X-Request-Start "t=${msec}";
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $thescheme;
      proxy_http_version 1.1;
      proxy_buffering off;
      proxy_pass http://$upstream;
      break;
    }

    # this means every file in public is tried first
    try_files $uri @discourse;
  }

  #location /downloads/ {
  #  internal;
  #  alias $public/;
  #}

  location @discourse {
    proxy_set_header Host $http_host;
    proxy_set_header X-Request-Start "t=${msec}";
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $thescheme;
    proxy_pass http://$upstream;
  }

}
