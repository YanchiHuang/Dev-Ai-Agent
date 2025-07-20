FROM debian:bookworm-slim

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

# 安裝 NVM
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 安裝 Node.js 22 和 AI Agent 工具
RUN bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use $NODE_VERSION && nvm alias default $NODE_VERSION && npm install -g @openai/codex @google/gemini-cli @anthropic-ai/claude-code"

# 設定 PATH 環境變數
RUN NODE_PATH=$(ls -d $NVM_DIR/versions/node/*/bin | head -1) && \
    echo "export PATH=$NODE_PATH:\$PATH" >> ~/.bashrc

# 設定 Git 全域設定
RUN git config --global core.autocrlf input \
    && git config --global user.name "ai agent" \
    && git config --global user.email "aiagent@example.com"

# 建立工作目錄
RUN mkdir -p /home/aiagent/workspace

# 設定預設工作目錄
WORKDIR /home/aiagent/workspace

# 確保 NVM 環境在每次登入時都可用
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc

# 暴露常用端口（可選）
EXPOSE 3000 8000 8080

# 預設命令
CMD ["/bin/bash"]