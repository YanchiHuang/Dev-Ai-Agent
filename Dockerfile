FROM debian:bookworm-slim

LABEL org.opencontainers.image.source=https://github.com/YanchiHuang/Dev-Ai-Agent
LABEL org.opencontainers.image.description="Dev-Ai-Agent 是一款專為 AI 開發者打造的 Docker 容器，整合 Codex / Gemini / Claude AI CLI 工具箱"
LABEL org.opencontainers.image.licenses=AGPL-3.0

# 設定環境變數
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=22
ENV NVM_DIR=/home/aiagent/.nvm
# SuperClaude 安裝方式: 可選 pipx | uv | pip | npm (可用 build-arg 覆蓋)
ARG SUPERCLAUDE_INSTALLER=pipx
ENV SUPERCLAUDE_INSTALLER=${SUPERCLAUDE_INSTALLER}

# 更新套件列表並安裝基本工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    zstd \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    python3 \
    python3-pip \
    python3-venv \
    python3-distutils \
    build-essential \
    pkg-config \
    libssl-dev \
    libffi-dev \
    pipx \
    vim \
    powerline \
    && rm -rf /var/lib/apt/lists/*

# 安裝 GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# 建立非 root 使用者
RUN useradd -m -s /bin/bash aiagent \
    && echo 'aiagent ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# 切換到 aiagent 使用者
USER aiagent
WORKDIR /home/aiagent

# 建立 config、workspace、ssh、projects、gemini 目錄並設定適當權限
RUN mkdir -p /home/aiagent/config /home/aiagent/workspace /home/aiagent/.ssh /home/aiagent/projects /home/aiagent/.gemini \
    && chmod 700 /home/aiagent/.ssh \
    && chmod 755 /home/aiagent/config /home/aiagent/workspace /home/aiagent/projects /home/aiagent/.gemini

# 複製 gitconfig 設定檔
COPY config/gitconfig /home/aiagent/.gitconfig

# 安裝 NVM (最新版本)
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# 切換 SHELL 為 bash -lc 以確保後續 RUN 可以載入 nvm 相關環境（減少重複 source 指令）
SHELL ["/bin/bash","-lc"]

# 安裝 Node.js 22 和 AI Agent 工具，並設定全域 PATH
RUN set -euxo pipefail \
    && source "$NVM_DIR/nvm.sh" \
    && nvm install "$NODE_VERSION" \
    && nvm alias default "$NODE_VERSION" \
    && nvm use "$NODE_VERSION" \
    && npm install -g @openai/codex @google/gemini-cli @anthropic-ai/claude-code @vibe-kit/grok-cli @pimzino/claude-code-spec-workflow \
    && echo "Node $(node -v) 已安裝"

# 將 Node 加入全域 PATH（建置期及執行期都生效）
ENV PATH="${NVM_DIR}/versions/node/v${NODE_VERSION}/bin:${PATH}"
ENV PATH="/home/aiagent/.local/bin:/home/aiagent/bin:${PATH}"

# 設定預設工作目錄
WORKDIR /home/aiagent/workspace

# 設定 bash 環境 (NVM, PATH, Powerline) - 同時支援互動式和非互動式 shell
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc \
    && echo 'nvm use 22 > /dev/null 2>&1' >> ~/.bashrc \
    && echo 'export PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"' >> ~/.bashrc \
    && echo 'export PATH="$HOME/.local/bin:$HOME/bin:$PATH"' >> ~/.bashrc \
    && echo 'POWERLINE_SCRIPT=/usr/share/powerline/bindings/bash/powerline.sh' >> ~/.bashrc \
    && echo 'if [ -f $POWERLINE_SCRIPT ]; then' >> ~/.bashrc \
    && echo '  source $POWERLINE_SCRIPT' >> ~/.bashrc \
    && echo 'fi' >> ~/.bashrc \
    && echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.profile \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.profile \
    && echo 'nvm use 22 > /dev/null 2>&1' >> ~/.profile \
    && echo 'export PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$HOME/.local/bin:$HOME/bin:$PATH"' >> ~/.profile

# ------------------------------------------------------------
# 安裝 uv (Python 套件 / 執行環境管理工具) 並整合 spec-kit
# ------------------------------------------------------------
# 1. 安裝 uv (只需單一靜態 binary) 2. 預先快取 specify 指令環境
# 3. 建立便利 wrapper 腳本，使用 "specify" 風格工作流：/specify /plan /tasks
RUN set -euxo pipefail \
    && mkdir -p /home/aiagent/bin \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && uv --version \
    && echo '[spec-kit] 預熱 specify 指令 (下載相依資源)' \
    && uvx --from git+https://github.com/github/spec-kit.git specify --help > /dev/null \
    && printf '#!/usr/bin/env bash\nexec uvx --from git+https://github.com/github/spec-kit.git specify "$@"\n' > /home/aiagent/bin/specify \
    && chmod +x /home/aiagent/bin/specify \
    && echo '# 快速建立新專案: specify init <project>' > /home/aiagent/bin/spec-kit-notes.txt \
    && echo '# 既有資料夾初始化: specify init --here' >> /home/aiagent/bin/spec-kit-notes.txt \
    && echo '# 規格撰寫: /specify <描述>' >> /home/aiagent/bin/spec-kit-notes.txt \
    && echo '# 技術規劃: /plan <技術與架構>' >> /home/aiagent/bin/spec-kit-notes.txt \
    && echo '# 任務拆解: /tasks' >> /home/aiagent/bin/spec-kit-notes.txt \
    && grep -q 'alias /specify=' ~/.bashrc || echo "alias /specify='specify'" >> ~/.bashrc \
    && grep -q 'alias /plan=' ~/.bashrc || echo "alias /plan='specify plan'" >> ~/.bashrc \
    && grep -q 'alias /tasks=' ~/.bashrc || echo "alias /tasks='specify tasks'" >> ~/.bashrc \
    && echo '# spec-kit aliases 已載入: /specify /plan /tasks' >> ~/.bashrc

# 複製並安裝 SuperClaude 腳本
COPY --chmod=755 config/claude/setup-SuperClaude.sh /home/aiagent/setup-SuperClaude.sh
RUN set -euxo pipefail \
    && echo "[SuperClaude] 使用 Python: $(python3 --version)" \
    && echo "[SuperClaude] 使用 Node: $(node --version)" \
    && /home/aiagent/setup-SuperClaude.sh || (echo "SuperClaude 安裝腳本失敗，列出日誌後終止" && cat /home/aiagent/superclaude_install.log || true && exit 1)


# 暴露常用端口（可選）
EXPOSE 3000 8000 8080

# 健康檢查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD bash -c 'source ~/.profile && node --version' || exit 1

# 預設命令
CMD ["/bin/bash"]
