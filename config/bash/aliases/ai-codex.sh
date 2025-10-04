# ai-codex.sh - Aliases for OpenAI Codex CLI
# Group: AI / Codex

alias cx='codex'
alias cxhat='codex --instructions ~/.codex/instructions.txt'
alias cxhelp='codex --help'
alias cxconfig='codex --config ~/.codex/config.toml'
alias cxfile='codex --file'
cxgod() { _run_danger codex --dangerously-bypass-approvals-and-sandbox "$@"; }
export -f cxgod
