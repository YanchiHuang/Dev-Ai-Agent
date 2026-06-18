#!/usr/bin/env bash
set -euo pipefail

CONFIG_SCRIPTS_DIR="${HOME}/config/scripts"
AGY_CONFIG_DIR="${HOME}/.gemini/antigravity-cli"

mkdir -p "${AGY_CONFIG_DIR}"

if [ -f "${CONFIG_SCRIPTS_DIR}/setup-aliases.sh" ]; then
  bash "${CONFIG_SCRIPTS_DIR}/setup-aliases.sh"
else
  printf '[agy] setup-aliases.sh not found at %s\n' "${CONFIG_SCRIPTS_DIR}" >&2
  exit 1
fi

if [ "$#" -gt 0 ]; then
  printf '[agy] Ignoring unsupported setup option(s): %s\n' "$*" >&2
fi

printf '[agy] Alias framework installed. Antigravity CLI config: %s\n' "${AGY_CONFIG_DIR}"
printf '[agy] RTK integration is not configured for agy because support is not confirmed.\n'
