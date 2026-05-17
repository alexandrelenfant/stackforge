#!/usr/bin/env sh

set -e

cd /app

if [ "${APP_ENV:-dev}" = "dev" ]; then
  if [ -f composer.json ] && [ ! -d vendor ]; then
    echo "📦 Installation des dépendances Composer..."
    composer install --no-interaction
  fi

  mkdir -p var/cache var/log
fi

exec "$@"