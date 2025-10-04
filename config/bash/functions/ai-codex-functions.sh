# ai-codex-functions.sh - Function helpers for Codex CLI
# These are loaded before aliases (see init.sh)

cxanalyze() {
  if [ -z "$1" ]; then
    echo "Usage: cxanalyze <file_path>"
    return 1
  fi
  codex --config ~/.codex/config.toml --file "$1" --instructions ~/.codex/instructions.txt
}

cxrefactor() {
  if [ -z "$1" ]; then
    echo "Usage: cxrefactor <file_path> [refactor_instructions]"
    return 1
  fi
  local refactor_prompt="Refactor this code to improve readability, performance, and maintainability."
  if [ -n "$2" ]; then
    refactor_prompt="$2"
  fi
  echo "$refactor_prompt" | codex --config ~/.codex/config.toml --file "$1"
}

cxexplain() {
  if [ -z "$1" ]; then
    echo "Usage: cxexplain <file_path>"
    return 1
  fi
  echo "Explain this code in detail, including its purpose, logic, and any potential improvements." | codex --config ~/.codex/config.toml --file "$1"
}
