# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

This is a Docker-based AI development environment that provides a containerized workspace with multiple AI CLI tools. The project creates a Debian-based container with pre-installed AI agent tools for development assistance.

### Key Components

- **Docker Container**: Based on `debian:bookworm-slim` with Node.js 22, Python 3, Git, and GitHub CLI
- **AI Tools**: Pre-installed Claude Code, Codex CLI, Gemini CLI, and Grok CLI via npm
- **User Environment**: Non-root user (`aiagent`) for security
- **Development Tools**: Git, Vim, Powerline, and essential development utilities

### Directory Structure

```
├── Dockerfile              # Container build configuration
├── docker-compose.yml      # Service orchestration
├── config/
│   ├── gitconfig          # Git configuration with aliases
│   ├── claude/            # Claude Code global configuration
│   │   ├── settings.json  # Claude Code user settings (model, editor, etc.)
│   │   ├── claude.json    # Claude Code main config (projects mapping)
│   │   ├── default_instructions.md # Global system prompt for Claude Code
│   │   └── setup-claude.sh # Quick setup script for aliases
│   ├── gemini/            # Gemini CLI configuration
│   │   ├── settings.json  # Gemini CLI settings (auth, theme, MCP servers)
│   │   ├── instructions.txt # Global system prompt for Gemini
│   │   └── setup-gemini.sh # Quick setup script for aliases
│   ├── codex/             # OpenAI Codex CLI configuration
│   │   ├── config.toml    # Codex CLI main configuration (model, behavior, etc.)
│   │   ├── instructions.txt # Global system prompt for Codex
│   │   └── setup-codex.sh # Quick setup script for aliases
│   └── ssh/               # SSH keys directory
└── workspace/             # Shared workspace (host ↔ container)
```

## Container Management Commands

### Build and Start

```bash
# Build and start the container
docker-compose up -d

# Build without cache (for updates)
docker-compose build --no-cache

# Enter the container
docker-compose exec aiagent bash
```

### Container Operations

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs aiagent

# Stop container
docker-compose down
```

## AI Tools Usage

The container includes these pre-installed AI CLI tools:

- **Claude Code**: `claude` command for AI assistance
- **Codex CLI**: `codex` command for OpenAI Codex
- **Gemini CLI**: `gemini` command for Google Gemini
- **Grok CLI**: `grok` command for Grok AI

All tools require their respective API keys to be set in the `.env` file.

### Claude Code Configuration

Claude Code has dedicated global configuration mounted at `~/.claude/`:

- **Main Config**: `~/.claude/claude.json` - Top-level settings with project mappings and global preferences
- **User Settings**: `~/.claude/settings.json` - User-level preferences (model, editor, tools)
- **Instructions**: `~/.claude/default_instructions.md` - Global system prompt for consistent AI behavior
- **Usage**: `claude chat --instructions ~/.claude/default_instructions.md`

Configuration priority (highest to lowest):

1. `~/.claude/claude.json` (main config with project mappings)
2. `~/.claude/settings.json` (user settings)
3. Project-specific `.claude/` settings

Create convenient aliases for Claude Code:

```bash
alias cc='claude'
alias cchat='claude chat'
alias cchelp='claude chat --instructions ~/.claude/default_instructions.md'
alias cskip='claude --dangerously-skip-permissions' # Use with caution: skips permission prompts
```

For quick setup, run the initialization script:

```bash
bash ~/.claude/setup-claude.sh
```

Note on cskip:

- The `cskip` alias uses `--dangerously-skip-permissions` to bypass permission prompts. This is risky and should only be used in trusted environments and repositories where you fully understand the implications.

### Gemini CLI Configuration

Gemini CLI has dedicated global configuration mounted at `~/.gemini/`:

- **Settings**: `~/.gemini/settings.json` - CLI behavior, auth type, and MCP server configurations
- **Instructions**: `~/.gemini/instructions.txt` - Global system prompt for consistent AI behavior
- **Usage**: `gemini chat --instructions ~/.gemini/instructions.txt`

Create convenient alias for Gemini with pre-loaded instructions:

```bash
alias gchat='gemini chat --instructions ~/.gemini/instructions.txt'
```

For quick setup, run the initialization script:

```bash
bash ~/.gemini/setup-gemini.sh
```

### Codex CLI Configuration

Codex CLI has dedicated global configuration mounted at `~/.codex/`:

- **Main Config**: `~/.codex/config.toml` - Main configuration with model settings, behavior options, and API settings
- **Instructions**: `~/.codex/instructions.txt` - Global system prompt for consistent AI behavior
- **Usage**: `codex --config ~/.codex/config.toml --instructions ~/.codex/instructions.txt`

Configuration features:

- Model selection and parameters (temperature, max_tokens)
- Output format preferences (markdown, line numbers)
- Approval modes (auto, suggest, manual)
- Default instructions file path

Create convenient aliases for Codex CLI:

```bash
alias cx='codex'
alias cxhat='codex --instructions ~/.codex/instructions.txt'
alias cxconfig='codex --config ~/.codex/config.toml'
```

For quick setup, run the initialization script:

```bash
bash ~/.codex/setup-codex.sh
```

Convenience functions available after setup:

- `cxanalyze <file>` - Analyze code file with instructions
- `cxrefactor <file> [prompt]` - Refactor code with optional custom prompt
- `cxexplain <file>` - Get detailed code explanation

## Environment Configuration

The project uses environment variables for configuration:

- `OPENAI_API_KEY`: Required for Codex CLI
- `GEMINI_API_KEY`: Required for Gemini CLI
- `ANTHROPIC_API_KEY`: Required for Claude Code
- `NODE_VERSION`: Controls Node.js version (default: 22)

## Git Configuration

Pre-configured Git settings include:

- User: "ai agent" <aiagent@example.com>
- Core settings: `autocrlf = input`, default editor `nano`
- Useful aliases: `st` (status), `co` (checkout), `br` (branch), `ci` (commit), `lg` (log --oneline --graph --decorate)

## Development Workflow

1. Modify `.env` file with your API keys
2. Start container: `docker-compose up -d`
3. Enter container: `docker-compose exec aiagent bash`
4. Work in `/home/aiagent/workspace` (synced with host `./workspace`)
5. Use AI tools for development assistance

## File Persistence

- `./workspace/` - Shared workspace between host and container
- `./config/` - Configuration files including Git, Claude Code, Gemini, and Codex settings
- `./config/claude/` - Claude Code global configuration (mounted to `~/.claude/`)
- `./config/gemini/` - Gemini CLI global configuration (mounted to `~/.gemini/`)
- `./config/codex/` - Codex CLI global configuration (mounted to `~/.codex/`)
- `~/.ssh` - SSH keys mounted read-only from host
- `projects` - Named volume for persistent project data
