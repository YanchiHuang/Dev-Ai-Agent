#!/bin/bash

# Codex CLI Quick Setup Script
# This script sets up convenient aliases and shortcuts for OpenAI Codex CLI

echo "🚀 Setting up Codex CLI aliases and shortcuts..."

# Create helpful aliases for Codex CLI
echo "Setting up aliases..."

# Add aliases to .bashrc if they don't exist
ALIASES=(
    "alias cx='codex'"
    "alias cxhat='codex --instructions ~/.codex/instructions.txt'"
    "alias cxhelp='codex --help'"
    "alias cxconfig='codex --config ~/.codex/config.toml'"
    "alias cxfile='codex --file'"
)

for alias_cmd in "${ALIASES[@]}"; do
    if ! grep -q "$alias_cmd" ~/.bashrc; then
        echo "$alias_cmd" >> ~/.bashrc
        echo "✅ Added: $alias_cmd"
    else
        echo "⏭️  Already exists: $alias_cmd"
    fi
done

# Create convenient functions
echo ""
echo "Setting up convenience functions..."

# Function for quick code analysis with instructions
FUNCTION_CODE='
# Codex CLI convenience functions
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
'

# Check if functions already exist
if ! grep -q "cxanalyze()" ~/.bashrc; then
    echo "$FUNCTION_CODE" >> ~/.bashrc
    echo "✅ Added convenience functions: cxanalyze, cxrefactor, cxexplain"
else
    echo "⏭️  Convenience functions already exist"
fi

echo ""
echo "🎉 Codex CLI setup complete!"
echo ""
echo "Available aliases:"
echo "  cx          - Short for 'codex'"
echo "  cxhat       - Codex with default instructions"
echo "  cxhelp      - Show Codex help"
echo "  cxconfig    - Use Codex with default config"
echo "  cxfile      - Analyze specific file"
echo ""
echo "Available functions:"
echo "  cxanalyze <file>           - Analyze code file with instructions"
echo "  cxrefactor <file> [prompt] - Refactor code with optional custom prompt"
echo "  cxexplain <file>           - Get detailed code explanation"
echo ""
echo "To use these immediately, run: source ~/.bashrc"
echo "Or restart your shell session."