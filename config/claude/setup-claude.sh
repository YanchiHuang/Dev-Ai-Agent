#!/bin/bash

# Claude Code Setup Script
# This script sets up convenient aliases and configurations for Claude Code

echo "Setting up Claude Code aliases and configurations..."

# Add useful Claude Code aliases to .bashrc
cat >> ~/.bashrc << 'EOF'

# Claude Code Aliases
alias cc='claude'
alias cchat='claude chat'
alias cedit='claude edit'
alias cconfig='claude config'
alias cinit='claude init'
# ⚠️ Danger: runs Claude with all permission prompts skipped.
alias ccgod='claude --dangerously-skip-permissions'

# Claude with default instructions
alias cchelp='claude chat --instructions ~/.claude/default_instructions.md'

# Quick project initialization
alias cproject='claude init --instructions ~/.claude/default_instructions.md'

EOF

# Create convenient symlinks
echo "Creating convenient symlinks..."
ln -sf ~/.claude/default_instructions.md ~/claude-instructions.md

# Set execute permissions
chmod +x ~/.claude/setup-claude.sh
echo "✅ Claude Code setup completed!"
echo ""
echo "Available aliases:"
echo "  cc        - claude command shortcut"
echo "  cchat     - claude chat"
echo "  cedit     - claude edit"
echo "  cconfig   - claude config"
echo "  cchelp    - claude chat with default instructions"
echo "  cproject  - claude init with default instructions"
echo "  ccgod     - claude with --dangerously-skip-permissions (use with extreme caution)"
echo ""
echo "Reload your shell or run: source ~/.bashrc"
