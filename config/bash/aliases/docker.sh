# docker.sh - Common Docker aliases
# Group: Core / Docker

alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dimg='docker images'
alias drm='docker rm -f'
alias drmi='docker rmi -f'
alias dnet='docker network ls'
alias dcompose='docker compose'
