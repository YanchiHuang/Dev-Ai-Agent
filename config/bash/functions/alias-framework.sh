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
# Added 'nocache' flag to bypass caching if needed: ai_cli_status nocache
ai_cli_status() {
  # Cache results in session variable for performance (lasts until shell is closed)
  if [ "$1" != "nocache" ] && [ -n "${_AI_CLI_STATUS_CACHE:-}" ]; then
    echo "${_AI_CLI_STATUS_CACHE}"
    return 0
  fi

  local output
  local tmp
  tmp=$(mktemp 2>/dev/null || echo "/tmp/ai_cli_status.$$")
  {
    echo '=== AI CLI availability ==='
    for c in claude codex copilot gemini; do
      if command -v "$c" >/dev/null 2>&1; then
        printf '  %-8s OK\n' "$c"
      else
        printf '  %-8s MISSING\n' "$c"
      fi
    done
  } > "$tmp"
  output=$(cat "$tmp")
  rm -f "$tmp"

  # Cache for this session
  _AI_CLI_STATUS_CACHE="$output"
  export _AI_CLI_STATUS_CACHE

  echo "$output"
}

# Search aliases by substring or regex; prefer fzf if installed
aliases_find() {
  if [ $# -eq 0 ]; then
    echo "Usage: aliases_find <pattern>" >&2
    return 1
  fi
  local pat="$1"
  if command -v fzf >/dev/null 2>&1; then
    alias | grep -i "$pat" | fzf --preview 'echo {}'
  else
    alias | grep -i "$pat"
  fi
}

# Generate documentation for all aliases
# Usage: aliases_doc [-m|--markdown] [-o file]
# Default output: plain text to stdout.
aliases_doc() {
  local mode="plain" out="";
  while [ $# -gt 0 ]; do
    case "$1" in
      -m|--markdown) mode="md";;
      -o) shift; out="$1";;
      --) shift; break;;
      *) echo "Unknown option: $1" >&2; return 1;;
    esac; shift || true
  done

  local tmp
  tmp=$(mktemp 2>/dev/null || echo "/tmp/aliases_doc.$$")
  {
    if [ "$mode" = md ]; then
      echo "# Alias Documentation"; echo
      echo "_Generated: $(date '+%Y-%m-%d %H:%M:%S')_"; echo
      echo "## Loaded Files"; echo '```'; aliases_sources 2>/dev/null || true; echo '```'; echo
      echo "## Aliases"; echo '```'
      alias | sed 's/^alias //'
      echo '```'
    else
      echo "Alias Documentation ($(date '+%Y-%m-%d %H:%M:%S'))"
      echo "Loaded files:"; aliases_sources 2>/dev/null || true; echo
      alias | sed 's/^alias //'
    fi
  } > "$tmp"

  if [ -n "$out" ]; then
    mv "$tmp" "$out"
    echo "Written: $out"
  else
    cat "$tmp"
    rm -f "$tmp"
  fi
}

export -f aliases_doc

export -f require_cmd _alias_confirm _run_danger aliases_sources aliases_list ai_cli_status aliases_find aliases_doc
