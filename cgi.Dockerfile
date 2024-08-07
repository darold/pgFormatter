FROM nginx:latest
RUN apt-get clean && apt-get update && apt-get install -y spawn-fcgi fcgiwrap libcgi-pm-perl libjson-perl libdata-dump-perl && rm -rf /var/lib/{apt,dpkg}
RUN sed -i 's/www-data/nginx/g' /etc/init.d/fcgiwrap
RUN chown nginx:nginx /etc/init.d/fcgiwrap
RUN <<EOR
cat > /etc/nginx/conf.d/default.conf <<EOF
server {
        listen 8080 default_server;
        root /var/www/html;
        index index.html index.htm;
        server_name _;
	location / {
	  gzip off;
	  fastcgi_pass  unix:/var/run/fcgiwrap.socket;
	  include /etc/nginx/fastcgi_params;
	  fastcgi_param SCRIPT_FILENAME  /app/pg_format;
	  fastcgi_param SERVER_NAME \$http_host;
	}
}
EOF
EOR
WORKDIR /app
ADD pg_format /app
ADD lib /app/lib
EXPOSE 8080
CMD /etc/init.d/fcgiwrap start \
    && nginx -g 'daemon off;'
