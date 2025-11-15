# syntax=docker/dockerfile:1.7-labs
######################################################################
# Multi-stage Build with Caching Optimizations for Dev-Ai-Agent
######################################################################

ARG BASE_IMAGE=debian:bookworm-slim
ARG NODE_VERSION=22
ARG NVM_VERSION=v0.40.1
ARG SPEC_KIT_REPO=git+https://github.com/github/spec-kit.git
ARG GLOBAL_NPM_PACKAGES="@openai/codex@latest @google/gemini-cli@latest @anthropic-ai/claude-code@latest @vibe-kit/grok-cli@latest @pimzino/claude-code-spec-workflow@latest ccusage@latest @github/copilot@latest @ast-grep/cli"

######################################################################
# Stage 1: base-apt (system packages only; reproducible & cached)
# - 僅裝系統基礎與 Python/pipx，保持 slim
# - 使用 BuildKit 快取掛載，加速 apt 流程
######################################################################
FROM ${BASE_IMAGE} AS base-apt
ARG NODE_VERSION
ARG NVM_VERSION
ARG SPEC_KIT_REPO
ARG GLOBAL_NPM_PACKAGES
LABEL org.opencontainers.image.source="https://github.com/YanchiHuang/Dev-Ai-Agent"
LABEL org.opencontainers.image.description="Dev-Ai-Agent multi-stage 基底 (system dependencies)"
LABEL org.opencontainers.image.licenses="AGPL-3.0"

ENV DEBIAN_FRONTEND=noninteractive

# 套件清單按字母序，便於檢視差異；同層清理 apt 緩存
# hadolint ignore=DL3008  # 使用發行版預設版本以維持安全更新
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    lsb-release \
    pipx \
    python3 \
    python3-distutils \
    python3-pip \
    python3-venv \
    sudo \
    vim \
    zstd \
    powerline; \
    rm -rf /var/lib/apt/lists/*

######################################################################
# Stage 2: builder
# - 安裝建置工具、NVM + Node、全域 npm CLI、uv/spec-kit
# - 建立非 root 使用者；練習教學導向 alias 與 notes
######################################################################
FROM base-apt AS builder
ARG NODE_VERSION
ARG NVM_VERSION
ARG SPEC_KIT_REPO
ARG GLOBAL_NPM_PACKAGES

ENV NVM_DIR=/home/aiagent/.nvm \
    NODE_VERSION=${NODE_VERSION} \
    SPEC_KIT_REPO=${SPEC_KIT_REPO}

# 僅 builder 需要的建置工具；同層清理
# hadolint ignore=DL3008  # 開發工具同樣依賴發行版版本維護
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    libssl-dev \
    pkg-config; \
    rm -rf /var/lib/apt/lists/*

# 建立非 root 使用者（固定 UID/GID=1000）
RUN groupadd -g 1000 aiagent || true \
    && useradd  -u 1000 -g 1000 -m -s /bin/bash aiagent \
    && echo 'aiagent ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER aiagent
WORKDIR /home/aiagent

# 個人設定（可獨立快取）
COPY --chown=aiagent:aiagent config/gitconfig /home/aiagent/.gitconfig

# 基本目錄
RUN mkdir -p config workspace .ssh projects .gemini bin \
    && chmod 700 .ssh

# 安裝 NVM + Node + 全域 npm CLI
SHELL ["/bin/bash","-o","pipefail","-c"]
# hadolint ignore=DL3016  # 安裝全域 CLI 套件故意使用 @latest（若需可重現建置，請在 CI 中傳入具體版本）
RUN set -eux; \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash; \
    source "$NVM_DIR/nvm.sh"; \
    nvm install ${NODE_VERSION}; \
    nvm alias default ${NODE_VERSION}; \
    nvm use ${NODE_VERSION}; \
    ln -sfn "$NVM_DIR/versions/node/$(nvm version default)" "$NVM_DIR/versions/node/current"; \
    npm install -g ${GLOBAL_NPM_PACKAGES}; \
    npm cache clean --force; \
    echo "[builder] Node $(node -v) 完成, npm global 安裝完成"

# 安裝 uv + 預熱 spec-kit（使用 pipx、保留教學 alias 與 notes）
# 將 heredoc 與後續 shell 命令拆成兩個 RUN，以避免 Dockerfile 解析 heredoc 後
# 將後續 shell 命令誤認為新指令（例如出現 "unknown instruction: chmod" 的錯誤）。
# shellcheck disable=SC2016  # 需在檔案中保留未展開的 $HOME 與 "$@" 字樣
# hadolint ignore=DL3013  # 安裝 uv 使用最新版本以便取得修正；若需可重現建置，請改為指定版本或在 CI 指定 UV_VERSION
RUN --mount=type=cache,target=/home/aiagent/.cache/uv,uid=1000,gid=1000 \
    set -eux; \
    export PATH="$HOME/.local/bin:$PATH"; \
    pipx install --pip-args='--no-cache-dir' uv || echo 'uv already installed'; \
    "$HOME/.local/bin/uv" --version; \
    echo '[spec-kit] 預熱 specify'; \
    "$HOME/.local/bin/uvx" --from ${SPEC_KIT_REPO} specify --help >/dev/null; \
    printf '%s\n' "#!/usr/bin/env bash" "export PATH=\"\$HOME/.local/bin:\$PATH\"" "exec uvx --from ${SPEC_KIT_REPO} specify \"\$@\"" > /home/aiagent/bin/specify; \
    chmod +x /home/aiagent/bin/specify; \
    ln -s "$HOME/.local/bin/uv"  /home/aiagent/bin/uv  || true; \
    ln -s "$HOME/.local/bin/uvx" /home/aiagent/bin/uvx || true; \
    # 合法 alias（不使用含斜線），保留教學導向操作體驗
    { \
    echo "alias plan='specify plan'"; \
    echo "alias tasks='specify tasks'"; \
    } >> ~/.bashrc; \
    printf '%s\n%s\n%s\n%s\n%s\n' \
    '# 快速建立新專案: specify init <project>' \
    '# 既有資料夾初始化: specify init --here' \
    '# 規格撰寫: specify <描述>' \
    '# 技術規劃: plan <技術與架構>' \
    '# 任務拆解: tasks' > /home/aiagent/bin/spec-kit-notes.txt

# Shell 環境設定（NVM + PATH；一次性加入 .bashrc/.profile）
RUN set -eux; \
    printf '%s\n' \
    "export NVM_DIR=\"\$HOME/.nvm\"" \
    "[ -s \"\$NVM_DIR/nvm.sh\" ] &&  . \"\$NVM_DIR/nvm.sh\"" \
    "[ -s \"\$NVM_DIR/bash_completion\" ] &&  . \"\$NVM_DIR/bash_completion\"" \
    "nvm use ${NODE_VERSION} > /dev/null 2>&1" \
    "export PATH=\"\$NVM_DIR/versions/node/current/bin:\$HOME/.local/bin:\$HOME/bin:\$PATH\"" \
    > ~/.bashrc; \
    cp ~/.bashrc ~/.profile

######################################################################
# Stage 3: final
# - 僅安裝執行期需要的工具（gh），複製 builder 成果
# - 統一一次性寫入 .profile（移除重複）
######################################################################
FROM base-apt AS final
ARG NODE_VERSION
ARG NVM_VERSION
ARG SPEC_KIT_REPO
ARG GLOBAL_NPM_PACKAGES
ARG UV_VERSION=0.4.20
SHELL ["/bin/bash","-o","pipefail","-c"]
LABEL org.opencontainers.image.source="https://github.com/YanchiHuang/Dev-Ai-Agent"
LABEL org.opencontainers.image.description="Dev-Ai-Agent 是一款專為 AI 開發者打造的容器 (multi-stage optimized)"
LABEL org.opencontainers.image.licenses="AGPL-3.0"

ENV DEBIAN_FRONTEND=noninteractive \
    NVM_DIR=/home/aiagent/.nvm \
    NODE_VERSION=${NODE_VERSION} \
    CHECK_CLI_UPDATES=1 \
    CHECK_CLI_PACKAGES="@openai/codex @google/gemini-cli @anthropic-ai/claude-code @vibe-kit/grok-cli @github/copilot"

# 執行期需用到的 GitHub CLI 與開發工具(保持最小依賴)
# hadolint ignore=DL3008  # 最小化依賴,沿用官方 gh 套件庫版本
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg; \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    cron \
    gh \
    python3 \
    python3-pip \
    pipx \
    fd-find \
    ripgrep \
    fzf \
    jq \
    yq \
    unzip; \
    rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL3008,DL4006
# 建立與 builder 一致的非 root 使用者
RUN groupadd -g 1000 aiagent || true \
    && useradd  -u 1000 -g 1000 -m -s /bin/bash aiagent \
    && echo 'aiagent ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER aiagent
WORKDIR /home/aiagent

# 僅複製執行期必要資源
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/.nvm                 /home/aiagent/.nvm
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/bin                  /home/aiagent/bin
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/.local/bin           /home/aiagent/.local/bin
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/.local/pipx          /home/aiagent/.local/pipx
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/.bashrc              /home/aiagent/.bashrc
COPY --chown=aiagent:aiagent --from=builder /home/aiagent/.gitconfig           /home/aiagent/.gitconfig

# 複製 runtime scripts（entrypoint + update checker）
COPY --chown=aiagent:aiagent --chmod=755 config/scripts/check-cli-updates.sh /home/aiagent/bin/check-cli-updates.sh
COPY --chown=aiagent:aiagent --chmod=755 config/scripts/entrypoint.sh        /home/aiagent/bin/entrypoint.sh

# 預設工作目錄與掛載點
RUN mkdir -p workspace projects .ssh .gemini config
WORKDIR /home/aiagent/workspace

# PATH：提供非互動 shell 也能直接叫到 node/npm/npx/uv 等
ENV PATH="/home/aiagent/.local/bin:/home/aiagent/.local/pipx/venvs/uv/bin:/home/aiagent/bin:/home/aiagent/.nvm/versions/node/current/bin:${PATH}"
ENV BASH_ENV=/home/aiagent/.bashrc

SHELL ["/bin/bash","-o","pipefail","-c"]
# 一次性寫入 ~/.profile（取代原先的「grep 然後再 printf 覆蓋」的重複流程）
RUN set -eux; \
    NVM_BIN_DIR="$NVM_DIR/versions/node/current/bin"; \
    if [ -d "$NVM_BIN_DIR" ]; then \
    ln -sf "$NVM_BIN_DIR/node" /usr/local/bin/node || true; \
    ln -sf "$NVM_BIN_DIR/npm"  /usr/local/bin/npm  || true; \
    ln -sf "$NVM_BIN_DIR/npx"  /usr/local/bin/npx  || true; \
    fi; \
    cat > /home/aiagent/.profile <<EOF
export NVM_DIR="\$HOME/.nvm"
export PATH="\$HOME/.local/bin:\$HOME/bin:\$NVM_DIR/versions/node/current/bin:\$PATH"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"
# 非互動 shell 也能使用預設 NODE_VERSION；若未安裝則嘗試安裝（開發友善）
nvm use ${NODE_VERSION} > /dev/null 2>&1 || nvm install ${NODE_VERSION}
EOF

RUN set -eux; \
    pipx ensurepath; \
    if ! command -v uvx >/dev/null 2>&1; then \
    pipx install --force "uv==${UV_VERSION}"; \
    fi; \
    uvx --version; \
    echo "[final] uvx installed and working."

# 健康檢查：Node 可用即視為健康
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD bash -lc 'node --version >/dev/null 2>&1 || exit 1'

EXPOSE 3000 8000 8080

ENTRYPOINT ["/home/aiagent/bin/entrypoint.sh"]
CMD ["/bin/bash"]

# 建置方式（啟用 BuildKit 以使用 cache mount）：
#   DOCKER_BUILDKIT=1 docker build -t dev-ai-agent:latest .
# 執行：
#   docker run -it --rm dev-ai-agent:latest
