#!/usr/bin/env bash

set -euo pipefail

SKELETON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="${SKELETON_DIR}/templates"

# =========================
# Spring Boot defaults
# =========================
# Ces valeurs sont centralisées pour faciliter la maintenance de Stackforge.
# Elles pourront être adaptées lorsque Spring Boot, Java ou Spring Initializr évoluent.

SPRING_INITIALIZR_URL="${SPRING_INITIALIZR_URL:-https://start.spring.io/starter.zip}"
SPRING_PROJECT_TYPE="${SPRING_PROJECT_TYPE:-maven-project}"
SPRING_LANGUAGE="${SPRING_LANGUAGE:-java}"
SPRING_BOOT_VERSION="${SPRING_BOOT_VERSION:-4.0.0}"
SPRING_GROUP_ID="${SPRING_GROUP_ID:-com.example}"
SPRING_ARTIFACT_ID="${SPRING_ARTIFACT_ID:-api}"
SPRING_NAME="${SPRING_NAME:-api}"
SPRING_PACKAGE_NAME="${SPRING_PACKAGE_NAME:-com.example.api}"
SPRING_PACKAGING="${SPRING_PACKAGING:-jar}"
SPRING_JAVA_VERSION="${SPRING_JAVA_VERSION:-25}"
SPRING_DEPENDENCIES="${SPRING_DEPENDENCIES:-web,actuator,validation}"

DOCKER_USER_ARGS=()
if command -v id >/dev/null 2>&1; then
  DOCKER_USER_ARGS=(--user "$(id -u):$(id -g)")
fi

normalize_identifier() {
  local value="$1"
  value="$(printf '%s' "${value}" | tr '[:upper:]' '[:lower:]')"
  value="$(printf '%s' "${value}" | sed -E 's/[[:space:]]+/_/g')"
  printf '%s' "${value}"
}

validate_identifier() {
  local value="$1"
  local label="$2"

  if [ -z "${value}" ]; then
    echo "❌ ${label} ne peut pas être vide."
    exit 1
  fi

  if [[ ! "${value}" =~ ^[a-z0-9_-]+$ ]]; then
    echo "❌ ${label} invalide : ${value}"
    echo "➡️  Caractères autorisés : lettres minuscules non accentuées, chiffres, tiret et underscore."
    exit 1
  fi
}

ensure_command() {
  local command_name="$1"
  local install_hint="$2"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "❌ Commande introuvable : ${command_name}"
    echo "➡️  ${install_hint}"
    exit 1
  fi
}

absolute_dirname() {
  local target_dir="$1"
  local parent_dir=""

  parent_dir="$(dirname "${target_dir}")"
  mkdir -p "${parent_dir}"
  (cd "${parent_dir}" && pwd)
}

run_symfony_new_lts() {
  local target_dir="$1"
  local parent_dir=""
  local target_name=""

  ensure_command "docker" "Installe Docker pour générer une API Symfony."

  rm -rf "${target_dir}"
  parent_dir="$(absolute_dirname "${target_dir}")"
  target_name="$(basename "${target_dir}")"

  docker build \
    -t stackforge/symfony-cli \
    "${SKELETON_DIR}/docker/symfony-cli"

  docker run --rm \
    "${DOCKER_USER_ARGS[@]}" \
    -e HOME=/tmp \
    -e COMPOSER_HOME=/tmp/composer \
    -e XDG_CONFIG_HOME=/tmp/.config \
    -e XDG_CACHE_HOME=/tmp/.cache \
    -v "${parent_dir}:/workspace" \
    -w /workspace \
    stackforge/symfony-cli \
    symfony new "${target_name}" \
      --version=lts \
      --api \
      --no-git
}

run_spring_initializr() {
  local spring_initializr_query=""

  ensure_command "docker" "Installe Docker pour générer une API Spring Boot."

  rm -rf "${PROJECT_DIR}/api"
  mkdir -p "${PROJECT_DIR}"

  echo "🌱 Génération d'une API Spring Boot Maven via Spring Initializr..."
  echo "   Spring Boot : ${SPRING_BOOT_VERSION}"
  echo "   Java        : ${SPRING_JAVA_VERSION}"
  echo "   Dependencies: ${SPRING_DEPENDENCIES}"

  spring_initializr_query="type=${SPRING_PROJECT_TYPE}"
  spring_initializr_query="${spring_initializr_query}&language=${SPRING_LANGUAGE}"
  spring_initializr_query="${spring_initializr_query}&bootVersion=${SPRING_BOOT_VERSION}"
  spring_initializr_query="${spring_initializr_query}&baseDir=api"
  spring_initializr_query="${spring_initializr_query}&groupId=${SPRING_GROUP_ID}"
  spring_initializr_query="${spring_initializr_query}&artifactId=${SPRING_ARTIFACT_ID}"
  spring_initializr_query="${spring_initializr_query}&name=${SPRING_NAME}"
  spring_initializr_query="${spring_initializr_query}&packageName=${SPRING_PACKAGE_NAME}"
  spring_initializr_query="${spring_initializr_query}&packaging=${SPRING_PACKAGING}"
  spring_initializr_query="${spring_initializr_query}&javaVersion=${SPRING_JAVA_VERSION}"
  spring_initializr_query="${spring_initializr_query}&dependencies=${SPRING_DEPENDENCIES}"

  docker run --rm \
    "${DOCKER_USER_ARGS[@]}" \
    -v "${PROJECT_DIR}:/workspace" \
    -e SPRING_INITIALIZR_URL \
    -e SPRING_INITIALIZR_QUERY="${spring_initializr_query}" \
    alpine:3.20 \
    sh -c 'apk add --no-cache curl unzip >/dev/null && curl -fsSL "${SPRING_INITIALIZR_URL}?${SPRING_INITIALIZR_QUERY}" -o /workspace/api.zip && unzip -q /workspace/api.zip -d /workspace && rm -f /workspace/api.zip'

  chmod +x "${PROJECT_DIR}/api/mvnw"
}

run_npm_create_vite() {
  local target_dir="$1"
  local template="$2"
  local parent_dir=""
  local target_name=""

  ensure_command "docker" "Installe Docker pour générer un projet Vite."

  rm -rf "${target_dir}"
  parent_dir="$(absolute_dirname "${target_dir}")"
  target_name="$(basename "${target_dir}")"

  docker run --rm \
    "${DOCKER_USER_ARGS[@]}" \
    -e HOME=/tmp \
    -e XDG_CACHE_HOME=/tmp/.cache \
    -e npm_config_cache=/tmp/npm-cache \
    -v "${parent_dir}:/workspace" \
    -w /workspace \
    node:lts-trixie \
    sh -c 'npm create vite@latest "$1" -- --template "$2" && npm --prefix "$1" install --package-lock-only' \
    sh "${target_name}" "${template}"
}

run_npm_nuxt_init() {
  local target_dir="$1"
  local parent_dir=""
  local target_name=""

  ensure_command "docker" "Installe Docker pour générer un projet Nuxt."

  rm -rf "${target_dir}"
  parent_dir="$(absolute_dirname "${target_dir}")"
  target_name="$(basename "${target_dir}")"

  docker run --rm \
    "${DOCKER_USER_ARGS[@]}" \
    -e HOME=/tmp \
    -e CI=true \
    -e npm_config_yes=true \
    -e NUXI_TELEMETRY_DISABLED=1 \
    -e npm_config_cache=/tmp/npm-cache \
    -v "${parent_dir}:/workspace" \
    -w /workspace \
    node:lts-trixie \
    sh -c "
      npm create nuxt@latest ${target_name} -- --git-init false --package-manager npm --no-modules --template minimal &&
      cd ${target_name} &&
      npm install --package-lock-only
    "
}

run_npx_angular_new() {
  local target_dir="$1"
  local parent_dir=""
  local target_name=""

  ensure_command "docker" "Installe Docker pour générer un projet Angular."

  rm -rf "${target_dir}"
  parent_dir="$(absolute_dirname "${target_dir}")"
  target_name="$(basename "${target_dir}")"

  docker run --rm \
    "${DOCKER_USER_ARGS[@]}" \
    -e HOME=/tmp \
    -e XDG_CACHE_HOME=/tmp/.cache \
    -e npm_config_cache=/tmp/npm-cache \
    -v "${parent_dir}:/workspace" \
    -w /workspace \
    node:lts-trixie \
    sh -c 'npx -y @angular/cli new "$1" --directory "$1" --routing --style=scss --skip-git --skip-install && npm --prefix "$1" install --package-lock-only' \
    sh "${target_name}"
}

run_npx_react_native_init() {
  local target_dir="$1"
  local parent_dir=""
  local target_name=""

  ensure_command "docker" "Installe Docker pour générer un projet React Native."

  rm -rf "${target_dir}"
  parent_dir="$(absolute_dirname "${target_dir}")"
  target_name="$(basename "${target_dir}")"

  docker run --rm \
    "${DOCKER_USER_ARGS[@]}" \
    -e HOME=/tmp \
    -e XDG_CACHE_HOME=/tmp/.cache \
    -e npm_config_cache=/tmp/npm-cache \
    -v "${parent_dir}:/workspace" \
    -w /workspace \
    node:lts-trixie \
    sh -c 'npx @react-native-community/cli init "$1" --directory "$1"' \
    sh "${target_name}"
}

ensure_target_is_empty_or_missing() {
  local target_dir="$1"

  if [ -e "${target_dir}" ] && [ "$(find "${target_dir}" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')" != "0" ]; then
    echo "❌ Le dossier cible existe déjà et n'est pas vide : ${target_dir}"
    echo "➡️  Choisis un autre dossier ou vide le dossier cible."
    exit 1
  fi
}

ask_api_kind() {
  local choice=""

  echo ""
  echo "Quel type d'API souhaites-tu ?"
  echo "  1) Dossier vide"
  echo "  2) Cloner un dépôt Git"
  echo "  3) PHP Symfony / FrankenPHP"
  echo "  4) Java Spring Boot / Maven"
  echo ""

  read -r -p "Choix [1/2/3/4] : " choice

  case "${choice}" in
    1)
      API_KIND="empty"
      ask_api_runtime
      ;;
    2)
      API_KIND="git"
      ask_api_runtime
      ;;
    3)
      API_KIND="php-symfony"
      API_RUNTIME="frankenphp"
      API_INTERNAL_PORT="80"
      ;;
    4)
      API_KIND="java-spring-boot"
      API_RUNTIME="spring-boot"
      API_INTERNAL_PORT="8080"
      ;;
    *)
      echo "❌ Choix invalide."
      exit 1
      ;;
  esac
}

ask_api_runtime() {
  local choice=""

  echo ""
  echo "Quel runtime Docker veux-tu utiliser pour l'API ?"
  echo "  1) PHP Symfony / FrankenPHP"
  echo "  2) Java Spring Boot / Maven"
  echo ""

  read -r -p "Choix [1/2] : " choice

  case "${choice}" in
    1)
      API_RUNTIME="frankenphp"
      API_INTERNAL_PORT="80"
      ;;
    2)
      API_RUNTIME="spring-boot"
      API_INTERNAL_PORT="8080"
      ;;
    *)
      echo "❌ Choix invalide."
      exit 1
      ;;
  esac
}

ask_web_kind() {
  local label="front"
  local default_vite_port="3000"
  local default_nuxt_port="5173"
  local default_angular_port="4200"
  local choice=""

  echo ""
  echo "Quel type de ${label} souhaites-tu ?"
  echo "  1) Dossier vide"
  echo "  2) Cloner un dépôt Git"
  echo "  3) Vue / Vite"
  echo "  4) React / Vite"
  echo "  5) Nuxt SSR"
  echo "  6) Angular"
  echo ""

  read -r -p "Choix [1/2/3/4/5/6] : " choice

  case "${choice}" in
    1)
      FRONT_KIND="empty"
      ask_web_runtime FRONT "${label}" "${default_vite_port}" "${default_nuxt_port}" "${default_angular_port}"
      ;;
    2)
      FRONT_KIND="git"
      ask_web_runtime FRONT "${label}" "${default_vite_port}" "${default_nuxt_port}" "${default_angular_port}"
      ;;
    3)
      FRONT_KIND="vue"
      FRONT_RUNTIME="node-vite"
      FRONT_INTERNAL_PORT="${default_vite_port}"
      FRONT_DEPLOY_MODE="static"
      ;;
    4)
      FRONT_KIND="react"
      FRONT_RUNTIME="node-vite"
      FRONT_INTERNAL_PORT="${default_vite_port}"
      FRONT_DEPLOY_MODE="static"
      ;;
    5)
      FRONT_KIND="nuxt"
      FRONT_RUNTIME="node-nuxt"
      FRONT_INTERNAL_PORT="${default_nuxt_port}"
      FRONT_DEPLOY_MODE="ssr"
      ;;
    6)
      FRONT_KIND="angular"
      FRONT_RUNTIME="node-angular"
      FRONT_INTERNAL_PORT="${default_angular_port}"
      FRONT_DEPLOY_MODE="static"
      ;;
    *)
      echo "❌ Choix invalide."
      exit 1
      ;;
  esac
}

ask_web_runtime() {
  local prefix="$1"
  local label="$2"
  local default_vite_port="$3"
  local default_nuxt_port="$4"
  local default_angular_port="$5"
  local choice=""

  echo ""
  echo "Quel runtime Docker veux-tu utiliser pour ${label} ?"
  echo "  1) Node / Vite"
  echo "  2) Node / Nuxt SSR"
  echo "  3) Node / Angular CLI"
  echo ""

  read -r -p "Choix [1/2/3] : " choice

  case "${choice}" in
    1)
      printf -v "${prefix}_RUNTIME" '%s' "node-vite"
      printf -v "${prefix}_INTERNAL_PORT" '%s' "${default_vite_port}"
      printf -v "${prefix}_DEPLOY_MODE" '%s' "static"
      ;;
    2)
      printf -v "${prefix}_RUNTIME" '%s' "node-nuxt"
      printf -v "${prefix}_INTERNAL_PORT" '%s' "${default_nuxt_port}"
      printf -v "${prefix}_DEPLOY_MODE" '%s' "ssr"
      ;;
    3)
      printf -v "${prefix}_RUNTIME" '%s' "node-angular"
      printf -v "${prefix}_INTERNAL_PORT" '%s' "${default_angular_port}"
      printf -v "${prefix}_DEPLOY_MODE" '%s' "static"
      ;;
    *)
      echo "❌ Choix invalide."
      exit 1
      ;;
  esac
}

ask_admin_kind() {
  local choice=""
  local label="admin"
  local default_vite_port="3001"
  local default_nuxt_port="5174"
  local default_angular_port="4201"

  echo ""
  echo "Souhaites-tu une interface ${label} ?"
  echo "  1) Non"
  echo "  2) Dossier vide"
  echo "  3) Cloner un dépôt Git"
  echo "  4) Vue / Vite"
  echo "  5) React / Vite"
  echo "  6) Nuxt SSR"
  echo "  7) Angular"
  echo ""

  read -r -p "Choix [1/2/3/4/5/6/7] : " choice

  case "${choice}" in
    1)
      ADMIN_ENABLED="false"
      PROJECT_TYPE="without-admin"
      ADMIN_KIND="none"
      ADMIN_RUNTIME="none"
      ADMIN_INTERNAL_PORT="5174"
      ADMIN_DEPLOY_MODE="static"
      ;;
    2)
      ADMIN_ENABLED="true"
      PROJECT_TYPE="with-admin"
      ADMIN_KIND="empty"
      ask_web_runtime ADMIN "${label}" "${default_vite_port}" "${default_nuxt_port}" "${default_angular_port}"
      ;;
    3)
      ADMIN_ENABLED="true"
      PROJECT_TYPE="with-admin"
      ADMIN_KIND="git"
      ask_web_runtime ADMIN "${label}" "${default_vite_port}" "${default_nuxt_port}" "${default_angular_port}"
      ;;
    4)
      ADMIN_ENABLED="true"
      PROJECT_TYPE="with-admin"
      ADMIN_KIND="vue"
      ADMIN_RUNTIME="node-vite"
      ADMIN_INTERNAL_PORT="${default_vite_port}"
      ADMIN_DEPLOY_MODE="static"
      ;;
    5)
      ADMIN_ENABLED="true"
      PROJECT_TYPE="with-admin"
      ADMIN_KIND="react"
      ADMIN_RUNTIME="node-vite"
      ADMIN_INTERNAL_PORT="${default_vite_port}"
      ADMIN_DEPLOY_MODE="static"
      ;;
    6)
      ADMIN_ENABLED="true"
      PROJECT_TYPE="with-admin"
      ADMIN_KIND="nuxt"
      ADMIN_RUNTIME="node-nuxt"
      ADMIN_INTERNAL_PORT="${default_nuxt_port}"
      ADMIN_DEPLOY_MODE="ssr"
      ;;
    7)
      ADMIN_ENABLED="true"
      PROJECT_TYPE="with-admin"
      ADMIN_KIND="angular"
      ADMIN_RUNTIME="node-angular"
      ADMIN_INTERNAL_PORT="${default_angular_port}"
      ADMIN_DEPLOY_MODE="static"
      ;;
    *)
      echo "❌ Choix invalide."
      exit 1
      ;;
  esac
}

ask_mobile_kind() {
  local choice=""

  echo ""
  echo "Souhaites-tu ajouter une application mobile ?"
  echo "  1) Non"
  echo "  2) Dossier vide"
  echo "  3) Cloner un dépôt Git"
  echo "  4) React Native"
  echo ""

  read -r -p "Choix [1/2/3/4] : " choice

  case "${choice}" in
    1)
      MOBILE_ENABLED="false"
      MOBILE_KIND="none"
      ;;
    2)
      MOBILE_ENABLED="true"
      MOBILE_KIND="empty"
      ;;
    3)
      MOBILE_ENABLED="true"
      MOBILE_KIND="git"
      ;;
    4)
      MOBILE_ENABLED="true"
      MOBILE_KIND="react-native"
      ;;
    *)
      echo "❌ Choix invalide."
      exit 1
      ;;
  esac
}

init_git_source() {
  local target_dir="$1"
  local label="$2"
  local repository=""
  local branch="main"
  local input_branch=""

  read -r -p "Repository ${label} [] : " repository
  read -r -p "Branche ${label} [main] : " input_branch
  branch="${input_branch:-main}"

  if [ -z "${repository}" ]; then
    echo "❌ Repository ${label} obligatoire pour le mode Git."
    exit 1
  fi

  ensure_command "git" "Installe Git puis relance la génération."

  rm -rf "${target_dir}"
  git clone --branch "${branch}" "${repository}" "${target_dir}"
}

init_api_source() {
  case "${API_KIND}" in
    empty)
      mkdir -p "${PROJECT_DIR}/api"
      ;;
    git)
      init_git_source "${PROJECT_DIR}/api" "API"
      ;;
    php-symfony)
      run_symfony_new_lts "${PROJECT_DIR}/api"
      ;;
    java-spring-boot)
      run_spring_initializr
      ;;
    *)
      echo "❌ API_KIND inconnu : ${API_KIND}"
      exit 1
      ;;
  esac
}

init_web_source() {
  local kind="$1"
  local target_dir="$2"
  local label="$3"

  case "${kind}" in
    empty)
      mkdir -p "${target_dir}"
      ;;
    git)
      init_git_source "${target_dir}" "${label}"
      ;;
    vue)
      run_npm_create_vite "${target_dir}" "vue"
      ;;
    react)
      run_npm_create_vite "${target_dir}" "react"
      ;;
    nuxt)
      run_npm_nuxt_init "${target_dir}"
      ;;
    angular)
      run_npx_angular_new "${target_dir}"
      ;;
    *)
      echo "❌ Type web inconnu pour ${label} : ${kind}"
      exit 1
      ;;
  esac
}

init_mobile_source() {
  case "${MOBILE_KIND}" in
    none)
      ;;
    empty)
      mkdir -p "${PROJECT_DIR}/mobile"
      ;;
    git)
      init_git_source "${PROJECT_DIR}/mobile" "Mobile"
      ;;
    react-native)
      run_npx_react_native_init "${PROJECT_DIR}/mobile"
      ;;
    *)
      echo "❌ MOBILE_KIND inconnu : ${MOBILE_KIND}"
      exit 1
      ;;
  esac
}

copy_docker_templates() {
  mkdir -p "${PROJECT_DIR}/infra/docker/api"
  mkdir -p "${PROJECT_DIR}/infra/docker/front"

  case "${API_RUNTIME}" in
    frankenphp)
      "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/api/frankenphp.Dockerfile.tpl" "${PROJECT_DIR}/infra/docker/api/Dockerfile"
      "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/api/frankenphp.xdebug.ini.tpl" "${PROJECT_DIR}/infra/docker/api/frankenphp.xdebug.ini"
      "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/api/frankenphp.docker-entrypoint.sh.tpl" "${PROJECT_DIR}/infra/docker/api/frankenphp.docker-entrypoint.sh"
      ;;
    spring-boot)
      "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/api/spring-boot.Dockerfile.tpl" "${PROJECT_DIR}/infra/docker/api/Dockerfile"
      ;;
    *)
      echo "❌ API_RUNTIME inconnu : ${API_RUNTIME}"
      exit 1
      ;;
  esac

  case "${FRONT_RUNTIME}" in
    node-vite)
      "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/front/node-vite.Dockerfile.tpl" "${PROJECT_DIR}/infra/docker/front/Dockerfile"
      "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/front/node-entrypoint.sh.tpl" "${PROJECT_DIR}/infra/docker/front/node-entrypoint.sh"
      ;;
    node-nuxt)
      "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/front/node-nuxt.Dockerfile.tpl" "${PROJECT_DIR}/infra/docker/front/Dockerfile"
      "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/front/node-entrypoint.sh.tpl" "${PROJECT_DIR}/infra/docker/front/node-entrypoint.sh"
      ;;
    node-angular)
      "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/front/node-angular.Dockerfile.tpl" "${PROJECT_DIR}/infra/docker/front/Dockerfile"
      "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/front/node-entrypoint.sh.tpl" "${PROJECT_DIR}/infra/docker/front/node-entrypoint.sh"
      ;;
    *)
      echo "❌ FRONT_RUNTIME inconnu : ${FRONT_RUNTIME}"
      exit 1
      ;;
  esac

  if [ "${ADMIN_ENABLED}" = "true" ]; then
    mkdir -p "${PROJECT_DIR}/infra/docker/admin"

    case "${ADMIN_RUNTIME}" in
      node-vite)
        "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/admin/node-vite.Dockerfile.tpl" "${PROJECT_DIR}/infra/docker/admin/Dockerfile"
        "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/admin/node-entrypoint.sh.tpl" "${PROJECT_DIR}/infra/docker/admin/node-entrypoint.sh"
        ;;
      node-nuxt)
        "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/admin/node-nuxt.Dockerfile.tpl" "${PROJECT_DIR}/infra/docker/admin/Dockerfile"
        "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/admin/node-entrypoint.sh.tpl" "${PROJECT_DIR}/infra/docker/admin/node-entrypoint.sh"
        ;;
      node-angular)
        "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/admin/node-angular.Dockerfile.tpl" "${PROJECT_DIR}/infra/docker/admin/Dockerfile"
        "${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/docker/admin/node-entrypoint.sh.tpl" "${PROJECT_DIR}/infra/docker/admin/node-entrypoint.sh"
        ;;
      *)
        echo "❌ ADMIN_RUNTIME inconnu : ${ADMIN_RUNTIME}"
        exit 1
        ;;
    esac
  fi
}

echo " Générateur de projet"
echo ""

read -r -p "Nom du projet [my_project] : " INPUT_PROJECT_NAME
RAW_PROJECT_NAME="${INPUT_PROJECT_NAME:-my_project}"
PROJECT_NAME="$(normalize_identifier "${RAW_PROJECT_NAME}")"
validate_identifier "${PROJECT_NAME}" "Nom du projet"

echo "➡️  Nom normalisé du projet : ${PROJECT_NAME}"

DEFAULT_TARGET_DIR="./${PROJECT_NAME}"
read -r -p "Dossier cible du projet [${DEFAULT_TARGET_DIR}] : " INPUT_TARGET_DIR
RAW_PROJECT_DIR="${INPUT_TARGET_DIR:-${DEFAULT_TARGET_DIR}}"

PROJECT_PARENT_DIR="$(dirname "${RAW_PROJECT_DIR}")"
PROJECT_BASENAME="$(basename "${RAW_PROJECT_DIR}")"
PROJECT_BASENAME="$(normalize_identifier "${PROJECT_BASENAME}")"
validate_identifier "${PROJECT_BASENAME}" "Nom du dossier cible"
PROJECT_DIR="${PROJECT_PARENT_DIR}/${PROJECT_BASENAME}"

echo "➡️  Dossier cible normalisé : ${PROJECT_DIR}"

ensure_target_is_empty_or_missing "${PROJECT_DIR}"

DEFAULT_DOMAIN_LCL="${PROJECT_NAME}.localhost"
read -r -p "Domaine local [${DEFAULT_DOMAIN_LCL}] : " INPUT_DOMAIN_LCL
DOMAIN_LCL="${INPUT_DOMAIN_LCL:-${DEFAULT_DOMAIN_LCL}}"

read -r -p "Domaine production optionnel [laisser vide] : " INPUT_DOMAIN
DOMAIN="${INPUT_DOMAIN:-}"

ask_api_kind
ask_web_kind
ask_admin_kind
ask_mobile_kind

echo ""
echo " Création de la structure projet : ${PROJECT_DIR}"

mkdir -p "${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}/infra"
mkdir -p "${PROJECT_DIR}/infra/certs"
mkdir -p "${PROJECT_DIR}/infra/reverse_proxy"
mkdir -p "${PROJECT_DIR}/infra/scripts"
mkdir -p "${PROJECT_DIR}/infra/docker"

touch "${PROJECT_DIR}/infra/certs/.gitkeep"

echo ""
echo " Initialisation des sources applicatives"

init_api_source
init_web_source "${FRONT_KIND}" "${PROJECT_DIR}/front" "Front"

if [ "${ADMIN_ENABLED}" = "true" ]; then
  init_web_source "${ADMIN_KIND}" "${PROJECT_DIR}/admin" "Admin"
fi

init_mobile_source

echo ""
echo " Génération des Dockerfiles"

copy_docker_templates

echo ""
echo " Génération des fichiers infra"

export ADMIN_ENABLED
export MOBILE_ENABLED
export PROJECT_NAME
export PROJECT_TYPE
export DOMAIN
export DOMAIN_LCL

export API_INTERNAL_PORT
export FRONT_INTERNAL_PORT
export ADMIN_INTERNAL_PORT

export FRONT_DEPLOY_MODE
export ADMIN_DEPLOY_MODE


"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/gitignore.tpl" "${PROJECT_DIR}/infra/.gitignore"

"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/env.tpl" "${PROJECT_DIR}/infra/.env"

"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/compose.yml.tpl" "${PROJECT_DIR}/infra/compose.yml"
"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/compose.dev.yml.tpl" "${PROJECT_DIR}/infra/compose.dev.yml"
"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/compose.prod.yml.tpl" "${PROJECT_DIR}/infra/compose.prod.yml"
"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/compose.test.yml.tpl" "${PROJECT_DIR}/infra/compose.test.yml"

"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/Caddyfile.dev.tpl" "${PROJECT_DIR}/infra/reverse_proxy/Caddyfile.dev"
"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/Caddyfile.prod.tpl" "${PROJECT_DIR}/infra/reverse_proxy/Caddyfile.prod"
"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/Caddyfile.test.tpl" "${PROJECT_DIR}/infra/reverse_proxy/Caddyfile.test"

"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/Makefile.tpl" "${PROJECT_DIR}/infra/Makefile"
"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/project.sh.tpl" "${PROJECT_DIR}/infra/project.sh"
"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/project.ps1.tpl" "${PROJECT_DIR}/infra/project.ps1"
"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/README.generated.md.tpl" "${PROJECT_DIR}/infra/README.md"
"${SKELETON_DIR}/scripts/render-template.sh" "${TEMPLATE_DIR}/generate-certs.sh.tpl" "${PROJECT_DIR}/infra/scripts/generate-certs.sh"

chmod +x "${PROJECT_DIR}/infra/project.sh"
chmod +x "${PROJECT_DIR}/infra/scripts/generate-certs.sh"

echo ""
echo "✅ Projet généré avec succès."
echo ""
echo "Nom du projet : ${PROJECT_NAME}"
echo "Dossier       : ${PROJECT_DIR}"
echo "Type          : ${PROJECT_TYPE}"
echo "API           : ${API_KIND} / ${API_RUNTIME} / port ${API_INTERNAL_PORT}"
echo "Front         : ${FRONT_KIND} / ${FRONT_RUNTIME} / port ${FRONT_INTERNAL_PORT} / ${FRONT_DEPLOY_MODE}"

if [ "${ADMIN_ENABLED}" = "true" ]; then
  echo "Admin         : ${ADMIN_KIND} / ${ADMIN_RUNTIME} / port ${ADMIN_INTERNAL_PORT} / ${ADMIN_DEPLOY_MODE}"
else
  echo "Admin         : non"
fi

if [ "${MOBILE_ENABLED}" = "true" ]; then
  echo "Mobile        : ${MOBILE_KIND}"
else
  echo "Mobile        : non"
fi

echo "Domaine local : ${DOMAIN_LCL}"

if [ -n "${DOMAIN}" ]; then
  echo "Domaine prod  : ${DOMAIN}"
else
  echo "Domaine prod  : non renseigné"
fi

echo ""
echo "Prochaines commandes :"
echo "  cd ${PROJECT_DIR}/infra"
echo "  ./project.sh certs"
echo "  ./project.sh dev"
