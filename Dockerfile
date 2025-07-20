FROM node:22

USER root

RUN apt-get update && apt-get install -y \
    git \
    curl \
    zstd \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

RUN npm install -g @openai/codex @google/gemini-cli @anthropic-ai/claude-code

RUN useradd -m -s /bin/bash aiagent
USER aiagent

RUN git config --global core.autocrlf input \
    && git config --global user.name "ai agent" \
    && git config --global user.email "aiagent@example.com"

WORKDIR /home/aiagent/workspace

CMD ["/bin/bash"]