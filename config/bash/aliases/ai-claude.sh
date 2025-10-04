# ai-claude.sh - Aliases for Anthropic Claude CLI
# Group: AI / Claude
# Loaded via init.sh

# Basic commands
alias cc='claude'
alias cchat='claude chat'
alias cedit='claude edit'
alias cconfig='claude config'
alias cinit='claude init'

# With default instructions
alias cchelp='claude chat --instructions ~/.claude/default_instructions.md'
alias cproject='claude init --instructions ~/.claude/default_instructions.md'

# Elevated / dangerous (wrapped with confirmation)
ccgod() { _run_danger claude --dangerously-skip-permissions "$@"; }
export -f ccgod
