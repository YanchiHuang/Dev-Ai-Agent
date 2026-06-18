#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: setup-rtk.sh [TARGET] [OPTIONS]

Targets:
  all      Configure Claude Code and Codex CLI (default)
  claude   Configure Claude Code global RTK setup
  codex    Configure Codex CLI global RTK setup

Options:
  --auto-patch  Auto-patch supported settings where available
  --no-patch    Skip settings patching where available
  --hook-only   Install hook only for supported targets
  --show        Show current RTK setup status
  --uninstall   Remove RTK setup for the selected target(s)
  -h, --help    Show this help
EOF
}

log() {
  printf '[setup-rtk] %s\n' "$*"
}

require_rtk() {
  if ! command -v rtk >/dev/null 2>&1; then
    printf '[setup-rtk][ERROR] rtk not found in PATH\n' >&2
    printf 'Rebuild the container or verify RTK installation first.\n' >&2
    exit 1
  fi
}

TARGET="all"
ACTION="install"
PATCH_FLAG=""
HOOK_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    all|claude|codex)
      TARGET="$1"
      ;;
    --auto-patch|--no-patch)
      PATCH_FLAG="$1"
      ;;
    --hook-only)
      HOOK_ONLY=1
      ;;
    --show)
      ACTION="show"
      ;;
    --uninstall)
      ACTION="uninstall"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '[setup-rtk][ERROR] Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ -n "$PATCH_FLAG" ] && [ "$ACTION" != "install" ]; then
  printf '[setup-rtk][ERROR] %s can only be used with install mode\n' "$PATCH_FLAG" >&2
  exit 1
fi

if [ "$HOOK_ONLY" -eq 1 ] && [ "$ACTION" != "install" ]; then
  printf '[setup-rtk][ERROR] --hook-only can only be used with install mode\n' >&2
  exit 1
fi

run_claude() {
  case "$ACTION" in
    install)
      local args=(init -g)
      [ -n "$PATCH_FLAG" ] && args+=("$PATCH_FLAG")
      [ "$HOOK_ONLY" -eq 1 ] && args+=(--hook-only)
      log "Configuring RTK for Claude Code"
      rtk "${args[@]}"
      ;;
    show)
      log "Showing RTK status for Claude Code"
      rtk init --show
      ;;
    uninstall)
      log "Removing RTK from Claude Code"
      rtk init -g --uninstall
      ;;
  esac
}

run_codex() {
  case "$ACTION" in
    install)
      log "Configuring RTK for Codex CLI"
      rtk init -g --codex
      ;;
    show)
      log "Showing RTK status for Codex CLI"
      rtk init --show --codex
      ;;
    uninstall)
      log "Removing RTK from Codex CLI"
      rtk init -g --codex --uninstall
      ;;
  esac
}

main() {
  require_rtk

  case "$TARGET" in
    all)
      run_claude
      run_codex
      ;;
    claude)
      run_claude
      ;;
    codex)
      run_codex
      ;;
  esac
}

main "$@"
