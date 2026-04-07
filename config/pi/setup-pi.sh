#!/usr/bin/env bash
set -euo pipefail

CONFIG_SCRIPTS_DIR="${HOME}/config/scripts"
PI_SESSION_DIR="/home/aiagent/projects/pi-sessions"

mkdir -p "${HOME}/.pi/agent" "${PI_SESSION_DIR}"
bash "${CONFIG_SCRIPTS_DIR}/setup-aliases.sh"

printf '%s\n' \
  "[pi] 已完成 alias framework 安裝。" \
  "[pi] Session 目錄：${PI_SESSION_DIR}" \
  "[pi] 請重新開啟 shell，或執行 source ~/.bashrc 以載入最新 alias。"
