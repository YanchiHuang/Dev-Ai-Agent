FROM debian:bookworm-slim

ARG NODE_VERSION=22
ENV NODE_VERSION=${NODE_VERSION}

RUN apt-get update && apt-get install -y \
    git \
    curl \
    zstd \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install gh -y \
    && rm -rf /var/lib/apt/lists/*

RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /root/.bashrc

ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && brew install pnpm

RUN useradd -m -s /bin/bash aiagent && \
    echo "aiagent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER aiagent
WORKDIR /home/aiagent

RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc

RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && \
    npm install -g @anthropics/claude-code-cli

COPY config/gitconfig /home/aiagent/.gitconfig

RUN mkdir -p /home/aiagent/workspace

WORKDIR /home/aiagent/workspace

CMD ["/bin/bash"]