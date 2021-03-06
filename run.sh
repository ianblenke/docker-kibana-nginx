#!/bin/bash
set -e

[ -n "$HOST" ] || ( echo "HOST required - You must supply the FQDN of the public host"; false )

SCHEME=${SCHEME:-https}
USERNAME=${USERNAME:-kibana}
PASSWORD=${PASSWORD:-kablammo}
ES_HOST=${ES_HOST:-172.17.42.1}
ES_PORT=${ES_PORT:-9200}

echo "$USERNAME:$(openssl passwd -crypt $PASSWORD)" > /passwords

sed -i -e 's%elasticsearch:.*9200",%elasticsearch: "'$SCHEME'://'$HOST'",%' /app/config.js

grep elasticsearch: /app/config.js

CONFDIR=/etc/nginx/conf
[ -d /etc/nginx/conf.d ] && CONFDIR=/etc/nginx/conf.d

[ -n "$CONFDIR/*" ] && rm -f $CONFDIR/*

cat <<EOF > $CONFDIR/default.conf
upstream elasticsearch {
  server $ES_HOST:$ES_PORT;
  keepalive 15;
}
server {
  listen                *:80 ;
  server_name           $HOST;
  access_log            /dev/stdout;
  error_log             /dev/stdout;

  # Enforce SSL
  if (\$http_x_forwarded_proto != 'https') {
    rewrite ^ https://\$host$request_uri? permanent;
  } 

  auth_basic "Protected Kibana";
  auth_basic_user_file /passwords;
  proxy_read_timeout 90;
  proxy_http_version 1.1;
  proxy_set_header Connection "Keep-Alive";
  proxy_set_header Proxy-Connection "Keep-Alive";

  proxy_set_header X-ELB-IP \$remote_addr;
  proxy_set_header X-ELB-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header Host $HOST;
  proxy_set_header Referer $HOST;

  location / {
   root /app;
   index  index.html  index.htm;
  }
  location ~ ^/_aliases\$ {
    proxy_pass http://elasticsearch;
  }
  location ~ ^/.*/_aliases\$ {
    proxy_pass http://elasticsearch;
  }
  location ~ ^/_nodes\$ {
    proxy_pass http://elasticsearch;
  }
  location ~ ^/.*/_search\$ {
    proxy_pass http://elasticsearch;
  }
  location ~ ^/.*/_mapping {
    proxy_pass http://elasticsearch;
  }
  location ~ ^/kibana-int/dashboard/.*\$ {
    proxy_pass http://elasticsearch;
  }
  location ~ ^/kibana-int/temp.*\$ {
    proxy_pass http://elasticsearch;
  }
}
EOF

echo Starting nginx
exec nginx -g "daemon off;"

