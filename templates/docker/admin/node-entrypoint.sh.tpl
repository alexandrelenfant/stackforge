#!/usr/bin/env sh

set -e

cd /app

if [ -f package.json ]; then
  echo "📦 Installation des dépendances npm..."
  npm install
fi

exec "$@"
