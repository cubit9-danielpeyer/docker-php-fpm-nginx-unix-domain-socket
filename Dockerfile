FROM alpine:3.10

LABEL Maintainer="reoring <reoring@craftsman-software.com>" \
      Description="with Nginx 1.16 & PHP-FPM 7.3 based on Alpine Linux."

ENV DOCUMENT_ROOT /app/html

# ensure we only use apk repositories over HTTPS (altough APK contain an embedded signature)
RUN echo "https://alpine.global.ssl.fastly.net/alpine/v$(cat /etc/alpine-release | cut -d . -f 1,2)/main" > /etc/apk/repositories \
	&& echo "https://alpine.global.ssl.fastly.net/alpine/v$(cat /etc/alpine-release | cut -d . -f 1,2)/community" >> /etc/apk/repositories

# The user the app should run as
ENV APP_USER=app
# The home directory
ENV APP_DIR="/$APP_USER"
# Where persistent data (volume) should be stored
ENV DATA_DIR "$APP_DIR/data"
# Where configuration should be stored
ENV CONF_DIR "$APP_DIR/conf"

# Update base system
RUN apk --no-cache upgrade && apk add --no-cache ca-certificates

# Install packages
RUN apk --no-cache add php7 php7-fpm php7-json php7-openssl php7-curl php7-gettext \
    php7-pdo php7-mysqli php7-pdo_mysql php7-pgsql php7-pdo_pgsql php7-sqlite3 \
    php7-pecl-redis \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session \
    php7-zip php7-bcmath php7-tokenizer \
    php7-mbstring php7-gd gettext nginx supervisor curl

RUN adduser -s /bin/true -u 1000 -D -h $APP_DIR $APP_USER \
  && mkdir "$DATA_DIR" "$CONF_DIR" \
  && chown -R "$APP_USER" "$APP_DIR" "$CONF_DIR" "$DATA_DIR" \
  && chmod 700 "$APP_DIR" "$DATA_DIR" "$CONF_DIR"

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
# RUN chown -R ${APP_USER}.${APP_USER} /run
RUN chown -R ${APP_USER}.${APP_USER} /var/lib/nginx && \
  chown -R ${APP_USER}.${APP_USER} /var/tmp/nginx && \
  chown -R ${APP_USER}.${APP_USER} /var/log/nginx

USER $APP_USER

# Create fpm directory that place sock file
RUN mkdir -p $DATA_DIR/run/php-fpm

# Configure nginx
COPY config/nginx.conf.template $CONF_DIR/

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make the document root a volume
VOLUME $APP_DIR/html

# Add application
WORKDIR $APP_DIR/html
COPY --chown=$APP_USER src/ $APP_DIR/html

# Expose the port nginx is reachable on
EXPOSE 8080

COPY entrypoint.sh $APP_DIR/

# Let supervisord start nginx & php-fpm
CMD ["/app/entrypoint.sh"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=3s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
