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
- `./config/` - Configuration files
- `~/.ssh` - SSH keys mounted read-only from host
- `projects` - Named volume for persistent project data