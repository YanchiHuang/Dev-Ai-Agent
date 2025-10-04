#!/usr/bin/env bash
set -euo pipefail

# setup-aliases.sh - Install modular alias framework into ~/.config/bash
# Idempotent: safe to re-run. Creates backup of .bashrc if modifying.

REPO_ROOT_ALIAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bash"
TARGET_ROOT="${HOME}/.config/bash"
BASHRC="${HOME}/.bashrc"
MARK_BEGIN="# >>> managed-alias-framework >>>"
MARK_END="# <<< managed-alias-framework <<<"

log() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }

ensure_dirs() {
  mkdir -p "${TARGET_ROOT}" "${TARGET_ROOT}/aliases" "${TARGET_ROOT}/functions"
}

sync_files() {
  rsync -a --delete "${REPO_ROOT_ALIAS_DIR}/" "${TARGET_ROOT}/" 2>/dev/null || cp -r "${REPO_ROOT_ALIAS_DIR}"/* "${TARGET_ROOT}/"
}

patch_bashrc() {
  touch "${BASHRC}"
  if ! grep -q "${MARK_BEGIN}" "${BASHRC}"; then
    cp "${BASHRC}" "${BASHRC}.bak.$(date +%Y%m%d-%H%M%S)"
    {
      echo ""; echo "${MARK_BEGIN}";
      cat <<'BLOCK'
# Load modular alias framework
if [ -f "$HOME/.config/bash/init.sh" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.config/bash/init.sh"
fi
BLOCK
      echo "${MARK_END}";
    } >> "${BASHRC}"
    log "Appended sourcing block to .bashrc"
  else
    log "Sourcing block already present in .bashrc"
  fi
}

main() {
  log "Installing modular alias framework..."
  ensure_dirs
  sync_files
  patch_bashrc
  log "Done. Open a new shell or run: source ~/.bashrc"
  log "Alias groups installed under: ${TARGET_ROOT}/aliases"
}

main "$@"
