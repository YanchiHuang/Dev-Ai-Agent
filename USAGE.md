# AI Agent Container 詳細使用說明

## 環境需求

- Docker
- Docker Compose

## 安裝與設定

### 1. 複製專案

```bash
git clone <your-repo-url>
cd <project-directory>
```

### 2. 環境設定

複製環境設定範例檔：

```bash
cp .env.example .env
```

編輯 `.env` 檔案，填入您的 API 金鑰：

```bash
# 必要設定
OPENAI_API_KEY=your_openai_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# 可選設定
NODE_VERSION=22
```

### 3. 建立容器

```bash
# 建立並啟動容器
docker-compose up -d

# 僅建立容器（不啟動）
docker-compose build
```

### 4. 進入容器

```bash
# 進入容器工作環境
docker-compose exec aiagent bash

# 或使用 docker 指令
docker exec -it aiagent bash
```

## AI 工具使用

容器內預裝以下 AI 工具：

### Claude Code CLI

```bash
# 初始化 Claude Code
claude-code auth

# 開始對話
claude-code

# 執行特定任務
claude-code "請幫我分析這個程式碼"
```

### Codex CLI (OpenAI)

```bash
# 使用 codex-cli
codex "write a python function to sort a list"
```

### Gemini CLI

```bash
# 使用 gemini-cli
gemini "explain this code snippet"
```

## 檔案管理

### 工作目錄

- 容器內工作目錄：`/home/aiagent/workspace`
- 主機掛載目錄：`./workspace`

所有在 `workspace` 目錄中的檔案會在主機和容器間同步。

### SSH 金鑰

將您的 SSH 金鑰放置在主機的 `~/.ssh` 目錄，容器會自動掛載（唯讀）。

### Git 設定

容器內已預設 Git 配置：

```bash
git config --global user.name "ai agent"
git config --global user.email "aiagent@example.com"
git config --global core.autocrlf input
```

您可以在容器內修改這些設定。

## 常用操作

### 重新建構容器

當修改 Dockerfile 或需要更新 Node.js 版本時：

```bash
docker-compose build --no-cache
docker-compose up -d
```

### 查看容器狀態

```bash
# 查看執行中的容器
docker-compose ps

# 查看容器日誌
docker-compose logs aiagent
```

### 停止容器

```bash
# 停止容器
docker-compose down

# 停止並刪除所有相關資源
docker-compose down -v
```

## 疑難排解

### 權限問題

如果遇到檔案權限問題：

```bash
# 在主機執行
sudo chown -R $USER:$USER ./workspace
```

### API 金鑰問題

確認 `.env` 檔案中的 API 金鑰正確設定：

```bash
# 在容器內檢查環境變數
echo $OPENAI_API_KEY
echo $GEMINI_API_KEY
echo $ANTHROPIC_API_KEY
```

### 網路連線問題

如果工具無法連接到 API：

```bash
# 測試網路連線
curl -I https://api.openai.com
curl -I https://generativelanguage.googleapis.com
curl -I https://api.anthropic.com
```

## 進階功能

### 自訂 Node.js 版本

在 `.env` 檔案中設定：

```bash
NODE_VERSION=18
```

然後重新建構容器：

```bash
docker-compose build --no-cache
```

### 安裝額外套件

進入容器後可使用包管理工具安裝額外軟體：

```bash
# 使用 apt
sudo apt update && sudo apt install <package-name>

# 使用 npm
npm install -g <package-name>

# 使用 brew
brew install <package-name>
```

## 安全注意事項

- 請勿將 `.env` 檔案提交到版本控制系統
- 定期更新 API 金鑰
- 確保 SSH 金鑰的安全性
- 容器以非 root 使用者執行，提升安全性