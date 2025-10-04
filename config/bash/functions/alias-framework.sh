# alias-framework.sh - Shared helpers for modular alias system
# Loaded before alias files by init.sh

# Require a command exist, else warn
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || printf '[alias-framework][MISSING] %s not found in PATH\n' "$1" >&2
}

# Confirm dangerous action
_alias_confirm() {
  local prompt=${1:-"Are you sure? (yes/no)"}
  local ans
  printf '%s ' "$prompt" >&2
  read -r ans
  case "$ans" in
    y|Y|yes|YES) return 0;;
    *) echo "Aborted." >&2; return 1;;
  esac
}

# Wrapper to run an underlying dangerous command
_run_danger() {
  local cmd="$1"; shift
  if _alias_confirm "Confirm elevated / dangerous operation: $cmd $* ? (yes/no)"; then
    eval "$cmd" "$@"
  fi
}

# List loaded alias files (init will populate ALIAS_FRAMEWORK_FILES)
aliases_sources() {
  printf '%s\n' ${ALIAS_FRAMEWORK_FILES:-}
}

# Dump grouped aliases (simple heuristic)
aliases_list() {
  echo '=== Aliases (filtered by pattern optional) ==='
  local pat=${1:-}
  if [ -n "$pat" ]; then
    alias | grep -E "$pat"
  else
    alias
  fi
}

# Show AI CLI status
ai_cli_status() {
  echo '=== AI CLI availability ==='
  for c in claude codex copilot gemini; do
    if command -v "$c" >/dev/null 2>&1; then
      printf '  %-8s OK\n' "$c"
    else
      printf '  %-8s MISSING\n' "$c"
    fi
  done
}

export -f require_cmd _alias_confirm _run_danger aliases_sources aliases_list ai_cli_status
