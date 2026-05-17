#!/usr/bin/env bash

set -euo pipefail

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_ENV_FILE="${INFRA_DIR}/.env"

if [ ! -f "${BASE_ENV_FILE}" ]; then
  echo "❌ Fichier .env introuvable : ${BASE_ENV_FILE}"
  exit 1
fi

show_help() {
  cat <<'EOF'
Available commands:
  ./project.sh certs  generate development certificates
  ./project.sh dev    start development environment
  ./project.sh test   start test environment
  ./project.sh prod   start production environment
  ./project.sh down   stop containers
  ./project.sh logs   show containers logs
  ./project.sh ps     show containers status
  ./project.sh help   show this help
EOF
}

dotenv_files_for() {
  local env_name="$1"

  printf '%s\n' \
    "${INFRA_DIR}/.env" \
    "${INFRA_DIR}/.env.${env_name}" \
    "${INFRA_DIR}/.env.local" \
    "${INFRA_DIR}/.env.${env_name}.local"
}

load_env() {
  local env_name="$1"
  local dotenv_file=""

  set -a
  while IFS= read -r dotenv_file; do
    if [ -f "${dotenv_file}" ]; then
      # shellcheck disable=SC1090
      source "${dotenv_file}"
    fi
  done < <(dotenv_files_for "${env_name}")
  set +a
}

compose_base() {
  local env_name="$1"
  local dotenv_file=""

  COMPOSE_BASE=(docker compose)

  while IFS= read -r dotenv_file; do
    if [ -f "${dotenv_file}" ]; then
      COMPOSE_BASE+=(--env-file "${dotenv_file}")
    fi
  done < <(dotenv_files_for "${env_name}")

  COMPOSE_BASE+=(-f "${INFRA_DIR}/compose.yml")
}

require_domain() {
  local env_name="$1"
  local env_label="$2"

  load_env "${env_name}"

  if [ -z "${DOMAIN:-}" ]; then
    echo "❌ DOMAIN n'est pas renseigné dans les fichiers dotenv de ${env_label}."
    echo "➡️  Renseigne un domaine dans .env, .env.local, .env.${env_name} ou .env.${env_name}.local."
    exit 1
  fi
}

command_name="${1:-help}"

case "${command_name}" in
  certs)
    echo "🔐 Generating development certificates..."
    load_env "dev"
    (cd "${INFRA_DIR}" && ./scripts/generate-certs.sh)
    ;;
  dev)
    echo "🚀 Starting DEV environment..."
    compose_base "dev"
    "${COMPOSE_BASE[@]}" -f "${INFRA_DIR}/compose.dev.yml" up --build -d
    ;;
  test)
    echo "🚀 Starting TEST environment..."
    compose_base "test"
    "${COMPOSE_BASE[@]}" -f "${INFRA_DIR}/compose.test.yml" up --build -d
    ;;
  prod)
    require_domain "prod" "production"
    echo "🚀 Starting PROD environment..."
    compose_base "prod"
    "${COMPOSE_BASE[@]}" -f "${INFRA_DIR}/compose.prod.yml" up --build -d
    ;;
  down)
    echo "🛑 Stopping containers..."
    compose_base "dev"
    "${COMPOSE_BASE[@]}" -f "${INFRA_DIR}/compose.dev.yml" down || true
    compose_base "test"
    "${COMPOSE_BASE[@]}" -f "${INFRA_DIR}/compose.test.yml" down || true
    compose_base "prod"
    "${COMPOSE_BASE[@]}" -f "${INFRA_DIR}/compose.prod.yml" down || true
    ;;
  logs)
    compose_base "${APP_ENV:-dev}"
    "${COMPOSE_BASE[@]}" logs -f
    ;;
  ps)
    compose_base "${APP_ENV:-dev}"
    "${COMPOSE_BASE[@]}" ps
    ;;
  help|-h|--help)
    show_help
    ;;
  *)
    echo "Unknown command: ${command_name}"
    echo ""
    show_help
    exit 1
    ;;
esac
