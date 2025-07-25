# 🧠 Dev-Ai-Agent

AI 開發助手容器，整合多個 CLI 工具（如 Codex、Gemini、Claude、Grok），基於 `debian:bookworm-slim` 製作，支援 Node.js、Python、Git 等開發工具，讓 AI 助手指令隨時隨地可用！

## 🛠️ 主要功能

- Codex CLI (`@openai/codex`)
- Gemini CLI (`@google/gemini-cli`)
- Claude Code CLI (`@anthropic-ai/claude-code`)
- Grok CLI (`@vibe-kit/grok-cli`)
- NVM / Node.js v22 / Python3 / Git / GH CLI
- 使用 `.env` 管理金鑰與設定
- 非 root 使用者執行，安全性佳

## DockerFile 預設安裝套件

- git
- nvm
- node 22
- curl
- zstd
- github cli
- python3
- powerline
- vim

## 提供以下 AI Agent 功能

- codex-cli：`npm install -g @openai/codex`
- gemini-cli：`npm install -g @google/gemini-cli`
- claude-code：`npm install -g @anthropic-ai/claude-code`
- grok-cli：`npm install -g @vibe-kit/grok-cli`

## git 設定

- git config --global core.autocrlf input
- git config --global user.name "ai agent"
- git config --global user.email "<aiagent@example.com>"

## Docker 使用方式

### 快速開始

1. **複製環境設定檔**

   ```bash
   cp .env.example .env
   ```

2. **編輯環境設定檔**

   - 開啟 `.env` 檔案
   - 填入您的 OpenAI API 金鑰、Gemini API 金鑰等

3. **建立並啟動容器**

   ```bash
   # 啟動基本AI Agent容器
   docker-compose up -d
   ```

4. **進入容器工作**

   ```bash
   docker-compose exec aiagent bash
   ```

### 檔案結構

```txt
.
├── Dockerfile              # Docker映像建構檔
├── docker-compose.yml      # Docker Compose設定檔
├── .env                    # 環境變數設定檔
├── .env.example           # 環境變數範例檔
├── USAGE.md               # 詳細使用說明
├── config/                # 設定檔目錄
│   ├── gitconfig          # Git設定檔
│   ├── ssh/               # SSH金鑰目錄
└── workspace/             # 工作目錄 (掛載到容器內)
```

### 功能特色

- **多版本支援**: 可透過環境變數指定 Node.js 版本
- **資料持久化**: 工作目錄和設定檔案會持久化保存
- **安全性**: 使用非 root 使用者執行容器

詳細使用說明請參考 `USAGE.md` 檔案。

### 進階設定

於 `.env` 檔案可自訂以下參數：

- `NODE_VERSION`：控制各工具版本

變更後請重新建構映像：

```bash
docker-compose build --no-cache
```
