# Gemini to Antigravity CLI (`agy`) Migration Plan

Date: 2026-06-19

## Goal

Remove Gemini CLI integration from this repository and replace it with Google
Antigravity CLI (`agy`).

This file started as the inventory and execution plan. It is also used as the
phase log while the migration is implemented.

## Phase Status

| Phase | Status | Commit |
| --- | --- | --- |
| 1. Confirm `agy` install/auth details | Done | `8f51ab4` |
| 2. Replace Docker install path | Done | `b481498` |
| 3. Replace config and aliases | Done | `f1e97eb` |
| 4. Remove Gemini env/config surface | Done | `d8c8789` |
| 5. Update documentation and editor metadata | Done | Pending |
| 6. Update CI and verification | Pending | Pending |

## Phase 1 Findings

Official references checked:

- Antigravity CLI install/auth docs:
  <https://antigravity.google/docs/cli-install>
- Gemini CLI migration docs:
  <https://antigravity.google/docs/gcli-migration>
- Antigravity CLI usage/settings docs:
  <https://antigravity.google/docs/cli-using>
  <https://antigravity.google/docs/cli-settings>
- Google Developers transition announcement:
  <https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/>

Confirmed implementation details:

- Linux/macOS install command is:
  `curl -fsSL https://antigravity.google/cli/install.sh | bash`
- The Unix installer supports `--dir <path>` and defaults to
  `$HOME/.local/bin`.
- The installed binary path is `$HOME/.local/bin/agy` unless `--dir` is used.
- The installer is non-interactive for the binary download path. It detects OS
  and architecture, fetches a platform manifest, downloads the release payload,
  verifies SHA512, installs `agy`, then runs `agy install`.
- The installer reports that Antigravity CLI self-updates in the background
  during normal runs.
- Antigravity CLI settings are stored under
  `~/.gemini/antigravity-cli/settings.json`.
- MCP servers are no longer stored inline in legacy
  `~/.gemini/settings.json`; Antigravity uses a dedicated MCP config file,
  commonly `~/.gemini/antigravity-cli/mcp_config.json`.
- Workspace context can use `AGENTS.md` or `GEMINI.md`; this repo already has
  `AGENTS.md` conventions, so new Gemini-specific prompt files should not be
  added unless needed for compatibility.

Phase 1 decisions:

- Install `agy` as a native binary in Docker, not as an npm package.
- Keep the persisted config mount under `~/.gemini`, but move repo-managed
  Antigravity files to `config/agy/antigravity-cli/` and mount
  `./config/agy:/home/aiagent/.gemini`.
- Do not migrate the corrupted legacy `config/gemini/instructions.md`.
- Convert the legacy inline Gemini MCP config into
  `config/agy/antigravity-cli/mcp_config.json`.
- Remove RTK Gemini integration rather than inventing an unverified `agy`
  target.

## Current Inventory

### Runtime / Build

| Path | Current Gemini usage | Migration action |
| --- | --- | --- |
| `Dockerfile` | `GLOBAL_NPM_PACKAGES` installs `@google/gemini-cli@latest`. | Remove `@google/gemini-cli`; add official `agy` installer step. |
| `Dockerfile` | Creates `/home/aiagent/.gemini` in builder/final stages. | Keep `.gemini` because Antigravity stores settings under `~/.gemini/antigravity-cli`. |
| `Dockerfile` | `CHECK_CLI_PACKAGES` includes `@google/gemini-cli`. | Remove Gemini from npm update checks; `agy` is not npm-managed. |
| `docker-compose.yml` | Passes `GEMINI_API_KEY`; mounts `./config/gemini` to `/home/aiagent/.gemini`. | Remove Gemini env; mount `./config/agy` to `/home/aiagent/.gemini`. |
| `.env.example` | Documents `GEMINI_API_KEY` and `GEMINI_MODEL`. | Remove Gemini env examples. |

### CLI Setup / Aliases

| Path | Current Gemini usage | Migration action |
| --- | --- | --- |
| `config/gemini/setup-gemini.sh` | Runs alias setup and `setup-rtk.sh gemini`. | Replace with `config/agy/setup-agy.sh`. |
| `config/gemini/settings.json` | Gemini CLI settings with inline MCP config. | Replace with `config/agy/antigravity-cli/settings.json` and `mcp_config.json`. |
| `config/gemini/instructions.md` | Intended Gemini instructions file, but content is corrupted. | Delete; rely on `AGENTS.md` and clean Antigravity config. |
| `config/bash/aliases/ai-gemini.sh` | Defines `gchat` and dangerous `ggod` around `gemini`. | Replace with conservative `ai-agy.sh`; avoid unverified Gemini flags. |
| `config/bash/init.sh` | Missing CLI notice checks `gemini`. | Replace `gemini` with `agy`. |
| `config/bash/functions/alias-framework.sh` | `ai_cli_status` checks `gemini`. | Replace `gemini` with `agy`. |
| `config/scripts/setup-rtk.sh` | Has explicit Gemini target and `rtk init -g --gemini`. | Remove Gemini target and keep RTK scoped to Claude/Codex. |
| `config/scripts/check-cli-updates.sh` | Default npm package list includes `@google/gemini-cli`. | Remove Gemini package. |

### Documentation

| Path | Current Gemini usage | Migration action |
| --- | --- | --- |
| `README.md` | Lists Gemini config, package, setup, env, CLI table, update command, aliases, VS Code recommendation. | Rewrite to Antigravity CLI and native install/update model. |
| `USAGE.md` | Documents Gemini env vars, RTK setup, usage, aliases, connectivity check, update list. | Rewrite to `agy` usage. |
| `CLAUDE.md` | Developer-facing repo guide describes Gemini CLI config and env vars. | Update to Antigravity CLI. |

### VS Code / CI

| Path | Current Gemini usage | Migration action |
| --- | --- | --- |
| `.vscode/extensions.json` | Recommends Gemini extensions. | Remove Gemini recommendations unless an official Antigravity extension ID is confirmed. |
| `.vscode/settings.json` | `"aitools.gemini.enabled": true`. | Replace with `aitools.agy.enabled`. |
| `.github/workflows/docker-build.yml` | CI verifies `gemini --version`. | Replace with `agy --version`. |

## Remaining Change Plan

### Phase 2 - Replace Docker install path

- Remove `@google/gemini-cli@latest` from `GLOBAL_NPM_PACKAGES`.
- Install `agy` with the official Unix installer using
  `curl -fsSL https://antigravity.google/cli/install.sh | bash`.
- Ensure `/home/aiagent/.local/bin` remains in `PATH`.
- Keep `.gemini` directory creation because Antigravity uses
  `~/.gemini/antigravity-cli`.
- Remove Gemini from `CHECK_CLI_PACKAGES`.

### Phase 3 - Replace config and aliases

- Replace `config/gemini/` with `config/agy/`.
- Add `config/agy/setup-agy.sh`.
- Add Antigravity settings and MCP config under
  `config/agy/antigravity-cli/`.
- Replace `config/bash/aliases/ai-gemini.sh` with
  `config/bash/aliases/ai-agy.sh`.
- Update shell status checks from `gemini` to `agy`.
- Remove Gemini target from `config/scripts/setup-rtk.sh`.

### Phase 4 - Remove Gemini env/config surface

- Remove `GEMINI_API_KEY` and `GEMINI_MODEL` from `.env.example`.
- Remove `GEMINI_API_KEY` from `docker-compose.yml`.
- Replace the compose config mount with `./config/agy:/home/aiagent/.gemini`.

### Phase 5 - Update documentation and editor metadata

- Update `README.md`, `USAGE.md`, and `CLAUDE.md`.
- Remove Gemini VS Code extension recommendations.
- Replace the workspace setting with `aitools.agy.enabled`.

### Phase 6 - Update CI and verification

- Update `.github/workflows/docker-build.yml` to check `agy --version`.
- Run static search for accidental Gemini runtime references.
- Build image:
  `docker build -t dev-ai-agent .`
- Smoke test:
  `docker run --rm --user aiagent dev-ai-agent bash -lc "codex --version && agy --version && claude --version"`

## Risks

- `agy` is installed as a native binary, so the existing npm update checker
  cannot manage it.
- Auth may require an interactive browser/device flow and must not be committed.
- The legacy Gemini instructions file is corrupted and should not be copied.
- RTK does not have confirmed Antigravity support in this repo.

## Completion Criteria

- No accidental runtime references remain for `gemini`,
  `@google/gemini-cli`, `GEMINI_`, or Gemini VS Code extension IDs.
- Docker image builds successfully.
- Container CLI check passes with `agy --version`.
- Docs no longer tell users to install, configure, or run Gemini CLI.
- No secrets, OAuth tokens, or local auth artifacts are committed.
