#!/usr/bin/env bash

set -euo pipefail

STACKFORGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
  cat <<'EOF'
Available commands:
  ./stackforge.sh generate        generate a new project interactively
  ./stackforge.sh install-alias   add the Stackforge alias to your shell rc file
  ./stackforge.sh help            show this help
EOF
}

dotenv_files_for() {
  local env_name="$1"

  printf '%s\n' \
    "${STACKFORGE_DIR}/.env" \
    "${STACKFORGE_DIR}/.env.${env_name}" \
    "${STACKFORGE_DIR}/.env.local" \
    "${STACKFORGE_DIR}/.env.${env_name}.local"
}

load_dotenv() {
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

install_alias() {
  local alias_name="${ALIAS_NAME:-stackforge}"
  local shell_name=""
  local rc_file=""
  local alias_line=""

  shell_name="$(basename "${SHELL:-}")"

  case "${shell_name}" in
    zsh)
      rc_file="${HOME}/.zshrc"
      ;;
    bash)
      rc_file="${HOME}/.bashrc"
      ;;
    *)
      if [ -n "${ZSH_VERSION:-}" ]; then
        rc_file="${HOME}/.zshrc"
      elif [ -n "${BASH_VERSION:-}" ]; then
        rc_file="${HOME}/.bashrc"
      elif [ -f "${HOME}/.zshrc" ]; then
        rc_file="${HOME}/.zshrc"
      else
        rc_file="${HOME}/.bashrc"
      fi
      ;;
  esac

  alias_line="alias ${alias_name}='\"${STACKFORGE_DIR}/stackforge.sh\" generate'"

  touch "${rc_file}"

  if grep -Fqx "${alias_line}" "${rc_file}"; then
    echo "Alias already installed in ${rc_file}:"
    echo "  ${alias_line}"
  elif grep -Eq "^alias ${alias_name}=" "${rc_file}"; then
    echo "An alias named '${alias_name}' already exists in ${rc_file}."
    echo "Update it manually or run with another name:"
    echo "  ALIAS_NAME=my-stackforge ./stackforge.sh install-alias"
    exit 1
  else
    printf '\n# Stackforge Project Generator\n%s\n' "${alias_line}" >> "${rc_file}"
    echo "Alias installed in ${rc_file}:"
    echo "  ${alias_line}"
    echo "Reload your shell with:"
    echo "  source ${rc_file}"
  fi
}

generate() {
  echo "🚀 Starting project generator..."
  chmod +x "${STACKFORGE_DIR}/scripts/"*.sh
  "${STACKFORGE_DIR}/scripts/init-project.sh"
}

command_name="${1:-help}"
load_dotenv "${command_name}"

case "${command_name}" in
  generate)
    generate
    ;;
  install-alias)
    install_alias
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
