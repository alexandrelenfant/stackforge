services:
  reverse_proxy:
    volumes:
{{#if FRONT_IS_STATIC}}
      - front_dist:/srv/frontend
{{/if}}
{{#if ADMIN_ENABLED}}
  {{#if ADMIN_IS_STATIC}}
      - admin_dist:/srv/admin
  {{/if}}
{{/if}}
      - ./reverse_proxy/Caddyfile.test:/etc/caddy/Caddyfile
    depends_on:
      front:
        condition: service_started
{{#if ADMIN_ENABLED}}
      admin:
        condition: service_started
{{/if}}

  front:
    build:
      target: web_prod
    environment:
      PUBLIC_API_BASE_URL: https://test.api.${DOMAIN_LCL}
{{#if FRONT_IS_STATIC}}
    volumes:
      - front_dist:/shared-dist
    restart: "no"
{{else}}
    expose:
      - "${FRONT_INTERNAL_PORT}"
    restart: "always"
{{/if}}

{{#if ADMIN_ENABLED}}
  admin:
    build:
      target: web_prod
    environment:
      PUBLIC_API_BASE_URL: https://test.api.${DOMAIN_LCL}
  {{#if ADMIN_IS_STATIC}}
    volumes:
      - admin_dist:/shared-dist
    restart: "no"
  {{else}}
    expose:
      - "${ADMIN_INTERNAL_PORT}"
    restart: "always"
  {{/if}}
{{/if}}

  api:
    build:
      target: api_prod
    environment:
      APP_ENV: test
      APP_DEBUG: 0
      SERVER_PORT: ${API_INTERNAL_PORT:-8080}
    expose:
      - "${API_INTERNAL_PORT}"

volumes:
{{#if FRONT_IS_STATIC}}
  front_dist:
{{/if}}
{{#if ADMIN_ENABLED}}
  {{#if ADMIN_IS_STATIC}}
  admin_dist:
  {{/if}}
{{/if}}