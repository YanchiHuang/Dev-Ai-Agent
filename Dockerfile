# syntax=docker/dockerfile:1.7-labs
######################################################################
# Multi-stage Build with Caching Optimizations for Dev-Ai-Agent       #
######################################################################

ARG BASE_IMAGE=debian:bookworm-slim
ARG NODE_VERSION=22
ARG SUPERCLAUDE_INSTALLER=pipx
ARG NVM_VERSION=v0.40.1
ARG SPEC_KIT_REPO=git+https://github.com/github/spec-kit.git
ARG GLOBAL_NPM_PACKAGES="@openai/codex @google/gemini-cli @anthropic-ai/claude-code @vibe-kit/grok-cli @pimzino/claude-code-spec-workflow ccusage"

######################################################################
# Stage 1: base-apt (system packages only; reproducible & cached)     #
######################################################################
FROM ${BASE_IMAGE} AS base-apt
ARG NODE_VERSION
ARG SUPERCLAUDE_INSTALLER
ARG NVM_VERSION
ARG SPEC_KIT_REPO
ARG GLOBAL_NPM_PACKAGES
LABEL org.opencontainers.image.source=https://github.com/YanchiHuang/Dev-Ai-Agent
LABEL org.opencontainers.image.description="Dev-Ai-Agent multi-stage 基底 (system dependencies)"
LABEL org.opencontainers.image.licenses=AGPL-3.0

ENV DEBIAN_FRONTEND=noninteractive

# 使用 BuildKit cache mount 加速 apt
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    git curl zstd ca-certificates gnupg lsb-release sudo \
    python3 python3-pip python3-venv python3-distutils pipx \
    build-essential pkg-config libssl-dev libffi-dev \
    vim powerline; \
    rm -rf /var/lib/apt/lists/*

# 安裝 GitHub CLI (獨立層, 若無變更可被快取)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg; \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y gh; \
    rm -rf /var/lib/apt/lists/*

######################################################################
# Stage 2: builder (install Node via NVM + global CLI tools + uv/spec) #
######################################################################
FROM base-apt AS builder
ARG NODE_VERSION
ARG SUPERCLAUDE_INSTALLER
ARG NVM_VERSION
ARG SPEC_KIT_REPO
ARG GLOBAL_NPM_PACKAGES

ENV NVM_DIR=/home/aiagent/.nvm \
    NODE_VERSION=${NODE_VERSION} \
    SUPERCLAUDE_INSTALLER=${SUPERCLAUDE_INSTALLER} \
    SPEC_KIT_REPO=${SPEC_KIT_REPO}

# 建立使用者 (固定 UID/GID=1000 以利 cache mount 權限設定)
RUN groupadd -g 1000 aiagent || true \
    && useradd -u 1000 -g 1000 -m -s /bin/bash aiagent \
    && echo 'aiagent ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER aiagent
WORKDIR /home/aiagent

# 複製 gitconfig (可快取，若更動會單獨失效)
COPY --chown=aiagent:aiagent config/gitconfig /home/aiagent/.gitconfig

# 建立目錄
RUN mkdir -p config workspace .ssh projects .gemini bin \
    && chmod 700 .ssh

# 安裝 NVM + Node + 全域 npm 套件 (分開層利於快取)
SHELL ["/bin/bash","-lc"]
RUN set -euxo pipefail; \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash; \
    source "$NVM_DIR/nvm.sh"; \
    nvm install ${NODE_VERSION}; \
    nvm alias default ${NODE_VERSION}; \
    nvm use ${NODE_VERSION}; \
    npm install -g ${GLOBAL_NPM_PACKAGES}; \
    npm cache clean --force; \
    echo "[builder] Node $(node -v) 完成, npm global 安裝完成"

# 安裝 uv + 預熱 spec-kit (使用 cache mount 以加速 uv 重複建置)
RUN --mount=type=cache,target=/home/aiagent/.cache/uv,uid=1000,gid=1000 \
    set -euxo pipefail; \
    curl -LsSf https://astral.sh/uv/install.sh | sh; \
    export PATH="$HOME/.local/bin:$PATH"; \
    "$HOME/.local/bin/uv" --version; \
    echo '[spec-kit] 預熱 specify'; \
    "$HOME/.local/bin/uvx" --from ${SPEC_KIT_REPO} specify --help >/dev/null; \
    printf '#!/usr/bin/env bash\nexport PATH="$HOME/.local/bin:$PATH"\nexec uvx --from %s specify "$@"\n' "$SPEC_KIT_REPO" > /home/aiagent/bin/specify; \
    chmod +x /home/aiagent/bin/specify; \
    ln -s "$HOME/.local/bin/uv" /home/aiagent/bin/uv || true; \
    ln -s "$HOME/.local/bin/uvx" /home/aiagent/bin/uvx || true; \
    # 修正: 先前使用 /specify /plan /tasks 作為 alias 名稱 (含斜線) 會觸發 bash: invalid alias name
    # 改為不含斜線的合法名稱，維持使用體驗 (使用者輸入 specify/plan/tasks)
    echo "alias specify='specify'" >> ~/.bashrc; \
    echo "alias plan='specify plan'" >> ~/.bashrc; \
    echo "alias tasks='specify tasks'" >> ~/.bashrc; \
    printf '%s\n%s\n%s\n%s\n%s\n' \
    '# 快速建立新專案: specify init <project>' \
    '# 既有資料夾初始化: specify init --here' \
    '# 規格撰寫: specify <描述>' \
    '# 技術規劃: plan <技術與架構>' \
    '# 任務拆解: tasks' > /home/aiagent/bin/spec-kit-notes.txt

# Shell 環境設定 (僅一次; 可快取)
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \\ . "$NVM_DIR/nvm.sh"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \\ . "$NVM_DIR/bash_completion"' >> ~/.bashrc \
    && echo "nvm use ${NODE_VERSION} > /dev/null 2>&1" >> ~/.bashrc \
    && echo 'export PATH="$NVM_DIR/versions/node/v'$NODE_VERSION'/bin:$HOME/.local/bin:$HOME/bin:$PATH"' >> ~/.bashrc \
    && echo 'POWERLINE_SCRIPT=/usr/share/powerline/bindings/bash/powerline.sh' >> ~/.bashrc \
    && echo 'if [ -f $POWERLINE_SCRIPT ]; then source $POWERLINE_SCRIPT; fi' >> ~/.bashrc \
    && cp ~/.bashrc ~/.profile

# 複製 SuperClaude 安裝腳本 (保持在 builder 先執行以快取)
COPY --chown=aiagent:aiagent --chmod=755 config/claude/setup-SuperClaude.sh /home/aiagent/setup-SuperClaude.sh
RUN set -euxo pipefail; \
    echo "[SuperClaude] Python: $(python3 --version)"; \
    echo "[SuperClaude] Node: $(node --version)"; \
    /home/aiagent/setup-SuperClaude.sh || (echo 'SuperClaude 安裝失敗 (builder 階段)'; cat /home/aiagent/superclaude_install.log || true; exit 1)

######################################################################
# Stage 3: final (copy only必要內容, 減少額外 cache/artifacts)           #
######################################################################
FROM ${BASE_IMAGE} AS final
ARG NODE_VERSION
ARG SUPERCLAUDE_INSTALLER
ARG NVM_VERSION
ARG SPEC_KIT_REPO
ARG GLOBAL_NPM_PACKAGES
LABEL org.opencontainers.image.source=https://github.com/YanchiHuang/Dev-Ai-Agent
LABEL org.opencontainers.image.description="Dev-Ai-Agent 是一款專為 AI 開發者打造的容器 (multi-stage optimized)"
LABEL org.opencontainers.image.licenses=AGPL-3.0

ENV DEBIAN_FRONTEND=noninteractive \
    NVM_DIR=/home/aiagent/.nvm \
    NODE_VERSION=${NODE_VERSION} \
    SUPERCLAUDE_INSTALLER=${SUPERCLAUDE_INSTALLER} \
    CHECK_CLI_UPDATES=1 \
    CHECK_CLI_PACKAGES="@openai/codex @google/gemini-cli @anthropic-ai/claude-code @vibe-kit/grok-cli"

# 安裝 runtime 必要套件 (避免重新安裝所有建置工具，可視需求裁剪)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    git curl zstd ca-certificates gnupg lsb-release sudo \
    python3 python3-pip python3-venv python3-distutils pipx \
    vim powerline; \
    rm -rf /var/lib/apt/lists/*

# 建立使用者 (需與 builder 相同 UID/GID)
RUN groupadd -g 1000 aiagent || true \
    && useradd -u 1000 -g 1000 -m -s /bin/bash aiagent \
    && echo 'aiagent ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER aiagent
WORKDIR /home/aiagent

# 從 builder 複製必要資源
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/.nvm /home/aiagent/.nvm
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/bin /home/aiagent/bin
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/.local/bin /home/aiagent/.local/bin
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/.bashrc /home/aiagent/.bashrc
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/.profile /home/aiagent/.profile
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/.gitconfig /home/aiagent/.gitconfig
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/superclaude_install.log /home/aiagent/superclaude_install.log
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/setup-SuperClaude.sh /home/aiagent/setup-SuperClaude.sh

# Copy runtime scripts (entrypoint + update checker)
COPY --chown=aiagent:aiagent --chmod=755 config/scripts/check-cli-updates.sh /home/aiagent/bin/check-cli-updates.sh
COPY --chown=aiagent:aiagent --chmod=755 config/scripts/entrypoint.sh /home/aiagent/bin/entrypoint.sh

# 預設工作空間
RUN mkdir -p workspace projects .ssh .gemini config
WORKDIR /home/aiagent/workspace

ENV PATH="/home/aiagent/.nvm/versions/node/v${NODE_VERSION}/bin:/home/aiagent/.local/bin:/home/aiagent/bin:${PATH}"

# 直接建立 node / npm / npx symlink 以供非互動 shell 使用
SHELL ["/bin/bash","-lc"]
RUN set -eux; \
    if [ -d "$NVM_DIR/versions/node/v${NODE_VERSION}/bin" ]; then \
    ln -sf $NVM_DIR/versions/node/v${NODE_VERSION}/bin/node /usr/local/bin/node || true; \
    ln -sf $NVM_DIR/versions/node/v${NODE_VERSION}/bin/npm /usr/local/bin/npm || true; \
    ln -sf $NVM_DIR/versions/node/v${NODE_VERSION}/bin/npx /usr/local/bin/npx || true; \
    fi; \
    grep -q 'nvm.sh' ~/.profile || echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm use ${NODE_VERSION} > /dev/null 2>&1' >> ~/.profile
RUN printf '%s\n%s\n%s\n%s\n' \
    'export NVM_DIR="$HOME/.nvm"' \
    'export PATH="$HOME/.local/bin:$HOME/bin:$NVM_DIR/versions/node/v'"${NODE_VERSION}"'/bin:$PATH"' \
    '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' \
    'nvm use ${NODE_VERSION} > /dev/null 2>&1 || nvm install ${NODE_VERSION}' > /home/aiagent/.profile
SHELL ["/bin/bash","-lc"]

# 健康檢查
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD bash -lc 'node --version >/dev/null 2>&1 || exit 1'

EXPOSE 3000 8000 8080

ENTRYPOINT ["/home/aiagent/bin/entrypoint.sh"]
CMD ["/bin/bash"]

# 使用方式: (建置時使用 BuildKit 以啟用 cache)
#   DOCKER_BUILDKIT=1 docker build -t dev-ai-agent:latest .
#   docker run -it --rm dev-ai-agent:latest
