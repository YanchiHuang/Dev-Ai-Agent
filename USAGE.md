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

編輯 `.env` 檔案，填入您的 API 金鑰與個人化設定：

```bash
# -------------------------
# --- AI API 金鑰 (必要) ---
# -------------------------
OPENAI_API_KEY=your_openai_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# ----------------------------------
# --- GitHub Copilot 設定 (可選) ---
# ----------------------------------
# 建議填寫 GH_TOKEN 以便在無瀏覽器環境中登入
GH_TOKEN=""
# 指定 Copilot 模型 (視 CLI 版本支援情況)
COPILOT_MODEL=""

# --------------------------
# --- AI 模型設定 (可選) ---
# --------------------------
# CLAUDE_CODE_MODEL=claude-3-sonnet-20240229
# OPENAI_MODEL=gpt-4
# GEMINI_MODEL=gemini-pro

# -------------------------
# --- 容器環境設定 (可選) ---
# -------------------------
# Node.js 版本 (預設: 22)
NODE_VERSION=22

# 設定您的時區 (預設: UTC)
TZ=Asia/Taipei

# 啟動時檢查 CLI 更新 (1=啟用, 0=停用)
CHECK_CLI_UPDATES=1

# 自動更新過期的 CLI (1=啟用, 0=停用)
CLI_AUTO_UPDATE=0
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
# 建議先執行一次設定腳本以安裝 alias
bash ~/.claude/setup-claude.sh

# 初始化 Claude Code
claude

# 開始對話
claude

# 執行特定任務
claude "請幫我分析這個程式碼"

# 跳過權限提示 (危險) — 需信任環境才使用
cskip  # 等同於：claude --dangerously-skip-permissions
# 完全跳過權限與安全防護 (極度危險)
ccgod  # 等同於：claude --dangerously-skip-permissions
```

注意：`cskip` 與 `ccgod` 會直接跳過 Claude Code 的權限請求流程，可能導致未經確認的檔案/命令操作，請僅在可信任的倉庫與可控環境使用。

### Codex CLI (OpenAI)

```bash
# 建議先執行一次設定腳本以安裝 alias
bash ~/.codex/setup-codex.sh

# 登入
codex login

# 使用 codex-cli
codex "write a python function to sort a list"

# 跳過 sandbox/審核 (極度危險)
cxgod "deploy my app"  # 等同於：codex --dangerously-bypass-approvals-and-sandbox "deploy my app"
```

注意：`cxgod` 會跳過 Codex CLI 的 sandbox 與審核步驟，請僅在完全受控的環境執行。

### Gemini CLI

```bash
# 建議先執行一次設定腳本以安裝 alias
bash ~/.gemini/setup-gemini.sh

# 使用 gemini-cli
gemini "explain this code snippet"

# 使用快速別名（含高風險指令）
gchat "請用繁中說明這段程式"  # 一般聊天快捷指令
ggod "直接改寫整個專案"       # 等同於：gemini --yolo "直接改寫整個專案"
```

注意：`ggod` 會以 `--yolo` 模式執行 Gemini CLI，跳過額外提示或確認。請僅在完全信任的專案環境內使用。

### GitHub Copilot CLI

```bash
# （可選）啟用 ctgod alias，讓 Copilot 以 --allow-all-tools 執行
bash config/scripts/setup-copilot-godmode.sh
```

> ⚠️ 警告：`ctgod` 會以 `copilot --allow-all-tools` 形式執行，跳過工具權限確認步驟，可能在未提示的情況下呼叫外部指令或修改檔案。請僅在完全信任的專案與執行環境中啟用，並確保瞭解其中風險。

## 檔案管理與資料持久化

本專案透過 `docker-compose.yml` 中的 `volumes` 設定，確保您的設定與工作成果得以保存。

### 主要工作目錄

- **`workspace/` (同步目錄)**
  - **容器內路徑**: `/home/aiagent/workspace`
  - **主機對應路徑**: `./workspace`
  - **說明**: 這是您的主要開發目錄，它會**即時**與主機上的 `workspace/` 資料夾雙向同步。所有您在此目錄中建立或修改的檔案，都可以直接在主機上用您偏好的 IDE 或編輯器開啟。

- **`projects/` (具名資料卷)**
  - **容器內路徑**: `/home/aiagent/projects`
  - **說明**: 這是一個由 Docker 管理的具名資料卷 (named volume)，適合存放不需要在主機上頻繁直接編輯，但希望在容器生命週期之間長期保存的資料，例如大型資料集、測試成品或次要專案。

### 設定檔掛載

- **`config/`**: 主機上的 `config` 目錄下的各工具設定檔 (如 `gemini`, `claude`, `codex`) 會被分別掛載至容器內家目錄的對應路徑 (如 `~/.gemini`)。這讓您可以直接在主機上透過 Git 版本控制所有 AI 工具的設定。

### SSH 金鑰

- 您的 SSH 金鑰 (`~/.ssh`) 會以**唯讀**模式掛載到容器中，方便您執行 Git 操作 (如 `git clone`, `git push`) 而無需在容器內重新設定金鑰。

### Git 設定

容器內已預設 Git 配置 (`.gitconfig`)，您隨時可以在容器內透過 `git config --global` 指令修改 `user.name` 和 `user.email`。

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

```

### 啟動時 CLI 版本檢查/自動更新

容器啟動時會執行 `config/scripts/check-cli-updates.sh`：

- `CHECK_CLI_UPDATES=1` 啟動時檢查全域 CLI 是否過期並列出更新指令
- `CLI_AUTO_UPDATE=1` 啟動時自動執行 `npm i -g <pkg>@latest` 更新偵測到過期的 CLI
- `CHECK_CLI_PACKAGES` 可自訂要檢查的套件清單（以空白分隔）

在單次啟動時臨時覆蓋設定：

```bash
CHECK_CLI_UPDATES=0 docker-compose up -d
CLI_AUTO_UPDATE=1 docker-compose up -d
```

## 安全注意事項

- 請勿將 `.env` 檔案提交到版本控制系統
- 定期更新 API 金鑰
- 確保 SSH 金鑰的安全性
- 容器以非 root 使用者執行，提升安全性
