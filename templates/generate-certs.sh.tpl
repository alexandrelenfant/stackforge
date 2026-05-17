#!/usr/bin/env bash

set -euo pipefail

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_ENV_FILE="${INFRA_DIR}/.env"

if [ ! -f "${BASE_ENV_FILE}" ]; then
  echo "❌ Fichier .env introuvable : ${BASE_ENV_FILE}"
  exit 1
fi

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

set -a
load_env "dev"
set +a

CERT_DIR="${INFRA_DIR}/certs"
DOMAIN_LCL="${DOMAIN_LCL:-localhost}"

echo "🔧 Vérification de mkcert"

if ! command -v mkcert >/dev/null 2>&1; then
  echo "❌ mkcert n'est pas installé."
  echo ""
  echo "Installation :"
  echo "  macOS   : brew install mkcert"
  echo "  Linux   : sudo apt install mkcert"
  echo "  Windows : choco install mkcert"
  exit 1
fi

echo "🔐 Installation de l'autorité locale mkcert"
mkcert -install

echo "📁 Création du dossier certs"
mkdir -p "${CERT_DIR}"
touch "${CERT_DIR}/.gitkeep"

DOMAINS=(
  "${DOMAIN_LCL}"
  "api.${DOMAIN_LCL}"
  "mail.${DOMAIN_LCL}"
{{#if ADMIN_ENABLED}}
  "admin.${DOMAIN_LCL}"
{{/if}}
  "test.${DOMAIN_LCL}"
{{#if ADMIN_ENABLED}}
  "test.admin.${DOMAIN_LCL}"
{{/if}}
)

echo "🔐 Génération des certificats de développement pour :"
printf '  - %s\n' "${DOMAINS[@]}"

mkcert \
  -cert-file "${CERT_DIR}/${DOMAIN_LCL}.pem" \
  -key-file "${CERT_DIR}/${DOMAIN_LCL}-key.pem" \
  "${DOMAINS[@]}"

echo "✅ Certificats de développement générés dans ${CERT_DIR}"
