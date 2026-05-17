services:
  reverse_proxy:
    volumes:
      - ./reverse_proxy/Caddyfile.dev:/etc/caddy/Caddyfile
      - ./certs:/certs
    depends_on:
      front:
        condition: service_started
{{#if ADMIN_ENABLED}}
      admin:
        condition: service_started
{{/if}}

{{#if ADMIN_ENABLED}}
  admin:
    build:
      target: web_dev
    environment:
      PUBLIC_API_BASE_URL: https://api.${DOMAIN_LCL}
    volumes:
      - ${ADMIN_DIR:-../admin}:/app
    expose:
      - "${ADMIN_INTERNAL_PORT}"

{{/if}}
  front:
    build:
      target: web_dev
    environment:
      PUBLIC_API_BASE_URL: https://api.${DOMAIN_LCL}
    volumes:
      - ${FRONT_DIR:-../front}:/app
    expose:
      - "${FRONT_INTERNAL_PORT}"

  api:
    build:
      target: api_dev
    environment:
      APP_ENV: dev
      XDEBUG_MODE: ${XDEBUG_MODE:-debug}
      XDEBUG_START_WITH_REQUEST: ${XDEBUG_START_WITH_REQUEST:-yes}
      XDEBUG_CLIENT_HOST: ${XDEBUG_CLIENT_HOST:-host.docker.internal}
      XDEBUG_CLIENT_PORT: ${XDEBUG_CLIENT_PORT:-9003}
      XDEBUG_IDEKEY: ${XDEBUG_IDEKEY:-}
      XDEBUG_CONFIG: >-
        client_host=${XDEBUG_CLIENT_HOST:-host.docker.internal}
        client_port=${XDEBUG_CLIENT_PORT:-9003}
        idekey=${XDEBUG_IDEKEY:-}
      PHP_IDE_CONFIG: ${PHP_IDE_CONFIG:-}
      SERVER_PORT: ${API_INTERNAL_PORT:-8080}
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ${API_DIR:-../api}:/app
    expose:
      - "${API_INTERNAL_PORT}"