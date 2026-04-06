#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

bash "${CONFIG_ROOT}/scripts/setup-aliases.sh"
bash "${CONFIG_ROOT}/scripts/setup-rtk.sh" claude "$@"
