# ai-copilot.sh - Aliases for GitHub Copilot CLI
# Group: AI / Copilot

ctgod() { _run_danger copilot --allow-all-tools "$@"; }
export -f ctgod
