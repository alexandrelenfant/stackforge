services:
  reverse_proxy:
    container_name: ${COMPOSE_PROJECT_NAME}_reverse_proxy
    image: caddy:2
    environment:
      DOMAIN: ${DOMAIN}
      DOMAIN_LCL: ${DOMAIN_LCL}
      HTTP_PORT: ${HTTP_PORT}
      HTTPS_PORT: ${HTTPS_PORT}
      API_INTERNAL_PORT: ${API_INTERNAL_PORT}
      FRONT_INTERNAL_PORT: ${FRONT_INTERNAL_PORT}
{{#if ADMIN_ENABLED}}
      ADMIN_INTERNAL_PORT: ${ADMIN_INTERNAL_PORT}
{{/if}}
    volumes:
      - caddy_data:/data
      - caddy_config:/config
    ports:
      - "${HTTP_PORT:-80}:${HTTP_PORT:-80}"
      - "${HTTPS_PORT:-443}:${HTTPS_PORT:-443}"
    restart: "always"

{{#if ADMIN_ENABLED}}
  admin:
    container_name: ${COMPOSE_PROJECT_NAME}_admin
    build:
      context: ../admin
      dockerfile: ../infra/docker/admin/Dockerfile
      additional_contexts:
        docker_web: ../infra/docker/admin
    depends_on:
      - api
    restart: "always"

{{/if}}
  front:
    container_name: ${COMPOSE_PROJECT_NAME}_front
    build:
      context: ../front
      dockerfile: ../infra/docker/front/Dockerfile
      additional_contexts:
        docker_web: ../infra/docker/front
    depends_on:
      - api
    restart: "always"

  api:
    container_name: ${COMPOSE_PROJECT_NAME}_api
    build:
      context: ../api
      dockerfile: ../infra/docker/api/Dockerfile
      additional_contexts:
        docker_api: ../infra/docker/api
    expose:
      - "${API_INTERNAL_PORT}"
    restart: "always"

volumes:
  caddy_data:
  caddy_config:
