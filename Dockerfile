FROM debian:bookworm-slim

LABEL org.opencontainers.image.source=https://github.com/YanchiHuang/Dev-Ai-Agent
LABEL org.opencontainers.image.description="開發用 AI Agent 容器環境，包含 Node.js、Python、GitHub CLI 及各種 AI 程式開發工具"
LABEL org.opencontainers.image.licenses=AGPL-3.0-only

# 設定環境變數
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=22
ENV NVM_DIR=/home/aiagent/.nvm

# 更新套件列表並安裝基本工具
RUN apt-get update && apt-get install -y \
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

# 建立 config、workspace、ssh、projects 目錄並設定適當權限
RUN mkdir -p /home/aiagent/config /home/aiagent/workspace /home/aiagent/.ssh /home/aiagent/projects \
    && chmod 700 /home/aiagent/.ssh \
    && chmod 755 /home/aiagent/config /home/aiagent/workspace /home/aiagent/projects

# 複製 gitconfig 設定檔
COPY config/gitconfig /home/aiagent/.gitconfig

# 安裝 NVM (最新版本)
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# 安裝 Node.js 22 和 AI Agent 工具
RUN bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use $NODE_VERSION && nvm alias default $NODE_VERSION && npm install -g @openai/codex @google/gemini-cli @anthropic-ai/claude-code"

# 設定預設工作目錄
WORKDIR /home/aiagent/workspace

# 設定 bash 環境 (NVM, PATH, Powerline) - 同時支援互動式和非互動式 shell
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc \
    && echo 'nvm use 22 > /dev/null 2>&1' >> ~/.bashrc \
    && echo 'export PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"' >> ~/.bashrc \
    && echo 'POWERLINE_SCRIPT=/usr/share/powerline/bindings/bash/powerline.sh' >> ~/.bashrc \
    && echo 'if [ -f $POWERLINE_SCRIPT ]; then' >> ~/.bashrc \
    && echo '  source $POWERLINE_SCRIPT' >> ~/.bashrc \
    && echo 'fi' >> ~/.bashrc \
    && echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.profile \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.profile \
    && echo 'nvm use 22 > /dev/null 2>&1' >> ~/.profile \
    && echo 'export PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"' >> ~/.profile

# 暴露常用端口（可選）
EXPOSE 3000 8000 8080

# 健康檢查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD bash -c 'source ~/.profile && node --version' || exit 1

# 預設命令
CMD ["/bin/bash"]