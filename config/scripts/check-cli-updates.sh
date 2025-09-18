#!/usr/bin/env bash
set -euo pipefail

# Check specific global npm CLIs for updates and print suggestions.

# Defaults to the four requested packages unless overridden via env.
PACKAGES_STR=${CHECK_CLI_PACKAGES:-"@openai/codex @google/gemini-cli @anthropic-ai/claude-code @vibe-kit/grok-cli"}

# Allow opt-out at runtime via env.
if [[ "${CHECK_CLI_UPDATES:-1}" != "1" ]]; then
  exit 0
fi

# Ensure npm is available in PATH (NVM paths are set in the image), but do a soft check.
if ! command -v npm >/dev/null 2>&1; then
  echo "[cli-check] npm is not available; skipping version check." >&2
  exit 0
fi

# Split packages into array safely (handles whitespace-separated list)
read -r -a PACKAGES <<<"${PACKAGES_STR}"
if [[ ${#PACKAGES[@]} -eq 0 ]]; then
  exit 0
fi

echo "[cli-check] Checking CLI updates for: ${PACKAGES_STR}"

# npm outdated exits with code 1 when updates are found. Capture JSON and continue.
OUTDATED_JSON=""
set +e
OUTDATED_JSON=$(npm outdated -g --json "${PACKAGES[@]}" 2>/dev/null)
STATUS=$?
set -e

# Network errors or unexpected outputs should not block container startup.
if [[ -z "${OUTDATED_JSON}" ]]; then
  if [[ ${STATUS} -ne 0 ]]; then
    echo "[cli-check] Unable to query npm registry at startup (status ${STATUS}). Skipping check." >&2
  else
    echo "[cli-check] All checked CLIs appear up-to-date."
  fi
  exit 0
fi

# If JSON is an empty object, nothing to update.
if [[ "${OUTDATED_JSON}" == "{}" ]]; then
  echo "[cli-check] All checked CLIs are up-to-date."
  exit 0
fi

echo "[cli-check] Updates available for the following global CLIs:"
echo ""

# Pretty print using a small Node helper (avoids adding jq dependency).
OUTDATED_LIST=$(echo "${OUTDATED_JSON}" | node -e '
let buf="";
process.stdin.on("data",d=>buf+=d).on("end",()=>{
  let o={};
  try { o = JSON.parse(buf||"{}"); } catch { o = {}; }
  const rows = Object.entries(o).map(([name, info]) => ({name, current: info.current, latest: info.latest}));
  for (const r of rows) {
    console.log(`  - ${r.name}: ${r.current} -> ${r.latest}`);
  }
  console.log("\n--PKG-LIST--");
  for (const r of rows) {
    console.log(r.name);
  }
});
')

# Split the combined output into the pretty section and the machine list
PRETTY_SECTION=$(printf "%s" "${OUTDATED_LIST}" | sed '/^--PKG-LIST--$/,$d')
ONLY_NAMES=$(printf "%s" "${OUTDATED_LIST}" | sed -n '/^--PKG-LIST--$/,$p' | sed '1d')

printf "%s\n" "${PRETTY_SECTION}"

echo ""
AUTO_UPDATE=${CLI_AUTO_UPDATE:-${CHECK_CLI_AUTO_UPDATE:-0}}

if [[ "${AUTO_UPDATE}" == "1" ]]; then
  echo "[cli-check] Auto-update enabled via CLI_AUTO_UPDATE=1."
  echo "[cli-check] Updating the following packages to latest:"
  while IFS= read -r pkg; do
    if [[ -n "$pkg" ]]; then
      echo "  - ${pkg}"
    fi
  done <<< "${ONLY_NAMES}"
  echo ""
  set +e
  # Perform a single npm install for all outdated packages to speed things up.
  PKG_ARGS=()
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && PKG_ARGS+=("${pkg}@latest")
  done <<< "${ONLY_NAMES}"
  if [[ ${#PKG_ARGS[@]} -gt 0 ]]; then
    npm i -g "${PKG_ARGS[@]}"
    NPM_STATUS=$?
    if [[ ${NPM_STATUS} -ne 0 ]]; then
      echo "[cli-check] Auto-update encountered errors (status ${NPM_STATUS}). See logs above." >&2
    else
      echo "[cli-check] Auto-update completed successfully."
    fi
  fi
  set -e
else
  echo "[cli-check] To update, run:"
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && echo "  npm i -g ${pkg}@latest"
  done <<< "${ONLY_NAMES}"
fi

echo ""
echo "[cli-check] Env vars:"
echo "  - CHECK_CLI_UPDATES=0 to skip checks"
echo "  - CLI_AUTO_UPDATE=1 to auto-update (alias: CHECK_CLI_AUTO_UPDATE)"

exit 0
