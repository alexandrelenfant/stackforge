#!/usr/bin/env bash

set -euo pipefail

TEMPLATE_FILE="${1:-}"
OUTPUT_FILE="${2:-}"

if [ -z "${TEMPLATE_FILE}" ] || [ -z "${OUTPUT_FILE}" ]; then
  echo "Usage: $0 <template-file> <output-file>"
  exit 1
fi

if [ ! -f "${TEMPLATE_FILE}" ]; then
  echo "❌ Template introuvable : ${TEMPLATE_FILE}"
  exit 1
fi

ADMIN_ENABLED="${ADMIN_ENABLED:-false}"
MOBILE_ENABLED="${MOBILE_ENABLED:-false}"

PROJECT_NAME="${PROJECT_NAME:-my_project}"
PROJECT_TYPE="${PROJECT_TYPE:-without-admin}"

DOMAIN="${DOMAIN:-}"
DOMAIN_LCL="${DOMAIN_LCL:-${PROJECT_NAME}.localhost}"

API_KIND="${API_KIND:-empty}"
API_RUNTIME="${API_RUNTIME:-none}"
API_INTERNAL_PORT="${API_INTERNAL_PORT:-80}"

FRONT_KIND="${FRONT_KIND:-empty}"
FRONT_RUNTIME="${FRONT_RUNTIME:-none}"
FRONT_INTERNAL_PORT="${FRONT_INTERNAL_PORT:-5173}"
FRONT_DEPLOY_MODE="${FRONT_DEPLOY_MODE:-dynamic}"

ADMIN_KIND="${ADMIN_KIND:-none}"
ADMIN_RUNTIME="${ADMIN_RUNTIME:-none}"
ADMIN_INTERNAL_PORT="${ADMIN_INTERNAL_PORT:-5174}"
ADMIN_DEPLOY_MODE="${ADMIN_DEPLOY_MODE:-dynamic}"

MOBILE_KIND="${MOBILE_KIND:-none}"

FRONT_IS_STATIC="false"
ADMIN_IS_STATIC="false"

if [ "${FRONT_DEPLOY_MODE}" = "static" ]; then
  FRONT_IS_STATIC="true"
fi

if [ "${ADMIN_DEPLOY_MODE}" = "static" ]; then
  ADMIN_IS_STATIC="true"
fi

mkdir -p "$(dirname "${OUTPUT_FILE}")"

awk \
  -v admin_enabled="${ADMIN_ENABLED}" \
  -v mobile_enabled="${MOBILE_ENABLED}" \
  -v front_is_static="${FRONT_IS_STATIC}" \
  -v admin_is_static="${ADMIN_IS_STATIC}" '
BEGIN {
  stack_size = 0
}

function push(val) {
  stack[++stack_size] = val
}

function pop() {
  if (stack_size > 0) {
    stack_size--
  }
}

function invert_top() {
  if (stack_size > 0) {
    if (stack[stack_size] == 1) {
      stack[stack_size] = 0
    } else {
      stack[stack_size] = 1
    }
  }
}

function should_print(i) {
  for (i = 1; i <= stack_size; i++) {
    if (stack[i] == 0) {
      return 0
    }
  }
  return 1
}

{
  if ($0 ~ /\{\{#if ADMIN_ENABLED\}\}/) {
    push(admin_enabled == "true")
    next
  }

  if ($0 ~ /\{\{#if MOBILE_ENABLED\}\}/) {
    push(mobile_enabled == "true")
    next
  }

  if ($0 ~ /\{\{#if FRONT_IS_STATIC\}\}/) {
    push(front_is_static == "true")
    next
  }

  if ($0 ~ /\{\{#if ADMIN_IS_STATIC\}\}/) {
    push(admin_is_static == "true")
    next
  }

  if ($0 ~ /\{\{else\}\}/) {
    invert_top()
    next
  }

  if ($0 ~ /\{\{\/if\}\}/) {
    pop()
    next
  }

  if (should_print()) {
    print
  }
}
' "${TEMPLATE_FILE}" \
  | sed \
      -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
      -e "s|{{PROJECT_TYPE}}|${PROJECT_TYPE}|g" \
      -e "s|{{DOMAIN}}|${DOMAIN}|g" \
      -e "s|{{DOMAIN_LCL}}|${DOMAIN_LCL}|g" \
      -e "s|{{API_INTERNAL_PORT}}|${API_INTERNAL_PORT}|g" \
      -e "s|{{FRONT_INTERNAL_PORT}}|${FRONT_INTERNAL_PORT}|g" \
      -e "s|{{ADMIN_INTERNAL_PORT}}|${ADMIN_INTERNAL_PORT}|g" \
  > "${OUTPUT_FILE}"

echo "✅ Généré : ${OUTPUT_FILE}"