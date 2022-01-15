FROM nginx:1.19
COPY default.conf /etc/nginx/conf.d
COPY website/ /usr/share/nginx/html/
COPY 30-update-urls.sh docker-entrypoint.d/
ENV NGINX_ENTRYPOINT_QUIET_LOGS=1
