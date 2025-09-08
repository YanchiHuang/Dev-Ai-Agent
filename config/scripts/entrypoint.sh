#!/usr/bin/env bash
set -euo pipefail

# Ensure PATH includes Node/npm (image already sets this, but keep as fallback)
export NVM_DIR="${NVM_DIR:-/home/aiagent/.nvm}"
if [[ -d "$NVM_DIR" && -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck disable=SC1090
  . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
fi

# Run CLI update check (non-blocking)
if [[ -x "/home/aiagent/bin/check-cli-updates.sh" ]]; then
  /home/aiagent/bin/check-cli-updates.sh || true
elif [[ -x "/home/aiagent/check-cli-updates.sh" ]]; then
  /home/aiagent/check-cli-updates.sh || true
fi

# Continue with the requested command
exec "$@"
