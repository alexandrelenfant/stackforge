FROM dunglas/frankenphp:php8.5-trixie AS api_base

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        unzip \
        curl \
        bash \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

FROM api_base AS api_dev

RUN install-php-extensions \
    pdo \
    pdo_mysql \
    intl \
    zip \
    opcache \
    xdebug

RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash \
    && apt-get update \
    && apt-get install -y --no-install-recommends symfony-cli \
    && rm -rf /var/lib/apt/lists/*

COPY --from=docker_api frankenphp.xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
COPY --from=docker_api frankenphp.docker-entrypoint.sh /usr/local/bin/docker-entrypoint

RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]

CMD ["frankenphp", "php-server", "-r", "public/", "--listen", "0.0.0.0:80"]

FROM api_base AS api_prod

RUN install-php-extensions \
    pdo \
    pdo_mysql \
    intl \
    zip \
    opcache

COPY . .

RUN if [ -f composer.json ]; then APP_ENV=prod APP_DEBUG=0 composer install --no-dev --optimize-autoloader --no-interaction; fi

CMD ["frankenphp", "php-server", "-r", "public/", "--listen", "0.0.0.0:80"]