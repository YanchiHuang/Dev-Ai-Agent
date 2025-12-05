# ~/.config/bash/init.sh (repository version)
# Loader script: sources all *.sh under aliases and functions directories.
# Safe, idempotent, and silent on missing directories.

BASH_CONFIG_ROOT="${HOME}/.config/bash"
ALIASES_DIR="${BASH_CONFIG_ROOT}/aliases"
FUNCTIONS_DIR="${BASH_CONFIG_ROOT}/functions"
ALIAS_FRAMEWORK_FILES=""

# Source functions first (they might be used by aliases)
if [ -d "${FUNCTIONS_DIR}" ]; then
  for f in "${FUNCTIONS_DIR}"/*.sh; do
    [ -r "$f" ] || continue
    # shellcheck disable=SC1090
    . "$f"
    ALIAS_FRAMEWORK_FILES+="$f "
  done
fi

# Then source alias groups
if [ -d "${ALIASES_DIR}" ]; then
  for f in "${ALIASES_DIR}"/*.sh; do
    [ -r "$f" ] || continue
    # shellcheck disable=SC1090
    . "$f"
    ALIAS_FRAMEWORK_FILES+="$f "
  done
fi

export ALIAS_FRAMEWORK_FILES

# Optional one-time per shell interactive notice (only if PS1 set and ai_cli_status defined)
# Lazy check: only verify if interactive and cache is missing
if [ -n "${PS1:-}" ] && [ -z "${_ALIAS_FRAMEWORK_STATUS_CHECKED:-}" ]; then
  _ALIAS_FRAMEWORK_STATUS_CHECKED=1
  # Quick check without running version commands (too slow)
  _missing=""
  for c in claude codex copilot gemini; do
    command -v "$c" >/dev/null 2>&1 || _missing="${_missing}${c} "
  done
  if [ -n "${_missing}" ]; then
    echo "[alias-framework] Missing AI CLI(s): ${_missing%% }. Run ai_cli_status for details." >&2
  fi
  unset _missing c
fi

unset BASH_CONFIG_ROOT ALIASES_DIR FUNCTIONS_DIR f
