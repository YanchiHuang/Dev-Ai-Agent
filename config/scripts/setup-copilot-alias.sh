#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="${HOME}/.bashrc"
ALIAS_LINE="alias ctgod='copilot --allow-all-tools'"

cat <<'WARN'
⚠️  WARNING: The ctgod alias runs GitHub Copilot CLI with --allow-all-tools, bypassing tool approval prompts. Enable only in fully trusted environments and repositories.
WARN

if [ ! -f "$TARGET_FILE" ]; then
  touch "$TARGET_FILE"
fi

if grep -Fxq "$ALIAS_LINE" "$TARGET_FILE"; then
  echo "Alias already present in $TARGET_FILE; no changes made."
else
  {
    echo
    echo "$ALIAS_LINE"
  } >> "$TARGET_FILE"
  echo "Alias appended to $TARGET_FILE. Restart your shell to use ctgod."
fi
