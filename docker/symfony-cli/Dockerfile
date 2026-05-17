FROM php:8.4-cli-alpine

RUN apk add --no-cache curl tar gzip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN curl -fsSL -o /tmp/symfony.tar.gz \
    https://github.com/symfony-cli/symfony-cli/releases/latest/download/symfony-cli_linux_amd64.tar.gz \
 && tar -xzf /tmp/symfony.tar.gz -C /tmp \
 && mv /tmp/symfony /usr/local/bin/symfony \
 && chmod +x /usr/local/bin/symfony \
 && rm -f /tmp/symfony.tar.gz