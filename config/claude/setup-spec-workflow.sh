#!/bin/bash
# Claude Code Spec Workflow setup helper
# Installs (if missing) and provides aliases & helper commands for @pimzino/claude-code-spec-workflow

set -euo pipefail

if ! command -v claude-code-spec-workflow >/dev/null 2>&1; then
  echo "[SpecWorkflow] Installing globally..."
  npm install -g @pimzino/claude-code-spec-workflow
fi

# Append aliases once
if ! grep -q 'spec-workflow aliases' ~/.bashrc 2>/dev/null; then
  cat >> ~/.bashrc <<'EOF'

# --- spec-workflow aliases --- (spec-workflow aliases)
# Setup current project (.claude structure)
alias spec-setup='claude-code-spec-workflow'
# Setup with all confirmations skipped
alias spec-setup-yes="claude-code-spec-workflow --yes"
# Steering docs generation
alias spec-steering='/spec-steering-setup'
# Create new feature spec
aalias spec-create='/spec-create'
# Execute a task id for a feature: usage: spec-exec 1 feature-name
alias spec-exec='claude-code-spec-workflow /spec-execute'
# Dashboard basic
alias spec-dash='npx -p @pimzino/claude-code-spec-workflow claude-spec-dashboard'
# Dashboard with tunnel
alias spec-dash-tunnel='npx -p @pimzino/claude-code-spec-workflow claude-spec-dashboard --tunnel'
# Optimized context helpers
alias spec-get-steering='claude-code-spec-workflow get-steering-context'
alias spec-get-spec='claude-code-spec-workflow get-spec-context'
alias spec-get-templates='claude-code-spec-workflow get-template-context'
# Bug workflow shortcuts
alias bug-create='/bug-create'
alias bug-analyze='/bug-analyze'
alias bug-fix='/bug-fix'
alias bug-verify='/bug-verify'
EOF
fi

echo "✅ Spec Workflow integration ready. Open a new shell or: source ~/.bashrc"
