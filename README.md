# docker-php-fpm-nginx-unix-domain-socket

This docker image is PHP 7.3 + FPM with nginx using unix domain docket based on alpine 3.10.

## Run

Run container.

```
docker run --rm \
    -v `pwd`/src:/var/www/html \
    -p 8080:8080 \
    reoring/php-fpm-nginx-unix-domain-socket
```

```
docker run \
    --rm \
    -v $(pwd)/src/laravel-app:/app/html \
    -e DOCUMENT_ROOT=/app/html/public \
    -p 8080:8080 php-fpm-uds
```