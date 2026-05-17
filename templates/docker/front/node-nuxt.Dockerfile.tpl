FROM node:lts-trixie AS web_base

WORKDIR /app

COPY --from=docker_web node-entrypoint.sh /usr/local/bin/node-entrypoint
RUN chmod +x /usr/local/bin/node-entrypoint

FROM web_base AS web_dev

ENTRYPOINT ["node-entrypoint"]
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "{{FRONT_INTERNAL_PORT}}"]

{{#if FRONT_IS_STATIC}}
FROM web_base AS web_prod

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run generate

CMD ["sh", "-c", "rm -rf /shared-dist/* && cp -r .output/public/* /shared-dist/"]
{{else}}
FROM web_base AS web_prod

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

CMD ["sh", "-c", "node .output/server/index.mjs"]
{{/if}}