#!/usr/bin/env bash
set -euo pipefail

# uninstall-aliases.sh - Remove modular alias framework files & bashrc block

TARGET_ROOT="${HOME}/.config/bash"
BASHRC="${HOME}/.bashrc"
MARK_BEGIN="# >>> managed-alias-framework >>>"
MARK_END="# <<< managed-alias-framework <<<"

log() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }

remove_block() {
  if grep -q "${MARK_BEGIN}" "${BASHRC}"; then
    cp "${BASHRC}" "${BASHRC}.bak.$(date +%Y%m%d-%H%M%S)"
    # sed portable approach (GNU assumed on Linux)
    sed -i "/${MARK_BEGIN}/,/${MARK_END}/d" "${BASHRC}"
    log "Removed sourcing block from .bashrc"
  else
    log "No sourcing block found in .bashrc"
  fi
}

remove_files() {
  if [ -d "${TARGET_ROOT}" ]; then
    rm -rf "${TARGET_ROOT}"
    log "Removed directory ${TARGET_ROOT}"
  else
    log "No directory ${TARGET_ROOT} to remove"
  fi
}

main() {
  log "Uninstalling modular alias framework..."
  remove_block
  remove_files
  log "Done. Restart your shell."
}

main "$@"
