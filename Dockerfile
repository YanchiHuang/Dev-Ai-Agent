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
    build-essential \
    && rm -rf /var/lib/apt/lists/*


COPY config/gitconfig /home/aiagent/.gitconfig

RUN mkdir -p /home/aiagent/workspace

WORKDIR /home/aiagent/workspace

CMD ["/bin/bash"]