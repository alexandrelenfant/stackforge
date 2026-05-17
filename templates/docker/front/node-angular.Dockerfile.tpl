FROM node:lts-trixie AS web_base

WORKDIR /app

COPY --from=docker_web node-entrypoint.sh /usr/local/bin/node-entrypoint
RUN chmod +x /usr/local/bin/node-entrypoint

FROM web_base AS web_dev

ENTRYPOINT ["node-entrypoint"]
CMD ["npm", "run", "start", "--", "--host", "0.0.0.0", "--port", "{{FRONT_INTERNAL_PORT}}"]

FROM web_base AS web_prod

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

CMD ["sh", "-c", "rm -rf /shared-dist/* && if [ -d dist/browser ]; then cp -r dist/browser/* /shared-dist/; else find dist -mindepth 2 -maxdepth 2 -type d -name browser -exec cp -r {}/* /shared-dist/ \\;; fi"]
