# FROM alpine:3.10
FROM ironpeakservices/hardened-alpine

LABEL Maintainer="reoring <reoring@craftsman-software.com>" \
      Description="with Nginx 1.16 & PHP-FPM 7.3 based on Alpine Linux."

# Update base system
RUN apk --no-cache upgrade && apk add --no-cache ca-certificates

# Install packages
RUN apk --no-cache add php7 php7-fpm php7-json php7-openssl php7-curl php7-gettext \
    php7-pdo php7-mysqli php7-pdo_mysql php7-pgsql php7-pdo_pgsql php7-sqlite3 \
    php7-pecl-redis \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session \
    php7-zip php7-bcmath \
    php7-mbstring php7-gd nginx supervisor=3.3.5-r0

# Configure nginx
COPY config/nginx.conf $CONF_DIR/

# Configure PHP-FPM
COPY config/fpm-pool.conf $CONF_DIR/www.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini

# Configure supervisord
#COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY config/supervisord.conf $CONF_DIR/

# Create fpm directory that place sock file
RUN mkdir -p $APP_DIR/tmp/php-fpm

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
# RUN chown -R nobody.nobody /run && \
#   chown -R nobody.nobody /var/lib/nginx && \
#   chown -R nobody.nobody /var/tmp/nginx && \
#   chown -R nobody.nobody /var/log/nginx && \
#   chown -R nobody.nobody /var/run/php-fpm

# Setup document root
RUN mkdir -p /var/www/html

# Make the document root a volume
VOLUME /var/www/html

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/app/conf/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=3s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
