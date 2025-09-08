# 🧠 Dev-Ai-Agent

AI 開發助手容器，整合多個 CLI 工具（如 Codex、Gemini、Claude、Grok），基於 `debian:bookworm-slim` 製作，支援 Node.js、Python、Git 等開發工具，讓 AI 助手指令隨時隨地可用！

## 🛠️ 主要功能

- Codex CLI (`@openai/codex`)
- Gemini CLI (`@google/gemini-cli`)
- Claude Code CLI (`@anthropic-ai/claude-code`)
- Grok CLI (`@vibe-kit/grok-cli`)
- Claude Usage 工具 (`ccusage`)
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

- [claude-code](https://www.npmjs.com/package/@anthropic-ai/claude-code)：Claude Code 是一款終端機 AI 編程助手，能理解您的程式碼庫，協助自動化日常任務、解釋複雜程式碼、處理 git 工作流，並可透過自然語言指令操作。

  - [SuperClaude_Framework](https://www.npmjs.com/package/@bifrost_inc/superclaude)：SuperClaude 是一套元編程配置框架，透過行為指令注入與元件協作，將 Claude Code 轉化為結構化開發平台，實現系統化工作流自動化與智慧代理協作。
  - [Claude Code Spec Workflow](https://www.npmjs.com/package/@pimzino/claude-code-spec-workflow)：自動化 Claude Code 工作流，支援規格驅動開發（需求 → 設計 → 任務 → 實作）與快速修復 bug 流程（回報 → 分析 → 修復 → 驗證）。
  - [ccusage](https://www.npmjs.com/package/ccusage)：分析本地 JSONL 檔案中的 Claude Code 使用情況的 CLI 工具。

- [codex-cli](https://www.npmjs.com/package/@openai/codex)：Codex CLI 是 OpenAI 推出的本地端 AI 編程代理，可直接在您的電腦上運行。
- [gemini-cli](https://www.npmjs.com/package/@google/gemini-cli)：Gemini CLI 是開源 AI 代理，將 Gemini 的強大能力帶入終端機，讓您能以最直接的方式存取 Gemini 模型。
- [grok-cli](https://www.npmjs.com/package/@vibe-kit/grok-cli)：Grok CLI 是一款對話式 AI 工具，具備智慧文字編輯與工具調用能力。

## 其他功能

- [spec-kit](https://github.com/github/spec-kit?tab=readme-ov-file#1-install-specify)：協助您快速開始規格驅動開發的工具包。

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

5. **設定 AI 工具別名 (可選)**

   ```bash
   # 設定 Claude Code 別名
   bash ~/.claude/setup-claude.sh

   # 設定 Gemini CLI 別名
   bash ~/.gemini/setup-gemini.sh

   # 設定 Codex CLI 別名
   bash ~/.codex/setup-codex.sh
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
│   ├── claude/            # Claude Code 全域配置
│   │   ├── settings.json  # 使用者設定 (模型、編輯器等)
│   │   ├── claude.json    # 主配置 (專案映射)
│   │   ├── default_instructions.md # 全域系統提示
│   │   └── setup-claude.sh # 快速設定腳本
│   ├── gemini/            # Gemini CLI 配置
│   │   ├── settings.json  # Gemini 設定檔
│   │   ├── instructions.txt # Gemini 系統提示
│   │   └── setup-gemini.sh # Gemini 設定腳本
│   ├── codex/             # OpenAI Codex CLI 配置
│   │   ├── config.toml    # Codex 主配置檔 (模型、行為等)
│   │   ├── instructions.txt # Codex 系統提示
│   │   └── setup-codex.sh # Codex 設定腳本
│   └── ssh/               # SSH金鑰目錄
└── workspace/             # 工作目錄 (掛載到容器內)
```

### 功能特色

- **多版本支援**: 可透過環境變數指定 Node.js 版本
- **資料持久化**: 工作目錄和設定檔案會持久化保存
- **安全性**: 使用非 root 使用者執行容器
- **全域配置**: 支援 Claude Code、Gemini CLI 與 Codex CLI 的全域設定管理
- **便利別名**: 預設提供常用 AI 工具的快捷指令

### 🔄 啟動時 CLI 版本檢查

容器每次啟動時，會檢查以下全域 npm CLI 是否有新版本，若非最新版則在啟動訊息中提示更新指令（不會自動更新）：

- `@openai/codex`
- `@google/gemini-cli`
- `@anthropic-ai/claude-code`
- `@vibe-kit/grok-cli`

運作方式：`config/scripts/entrypoint.sh` 會呼叫 `config/scripts/check-cli-updates.sh`，透過 `npm outdated -g --json` 比對目前已安裝版本與最新版本。若網路不可用或查詢失敗，將略過檢查且不影響容器啟動。

環境變數設定：

- `CHECK_CLI_UPDATES`：預設 `1`（啟用）；設為 `0` 可停用啟動檢查。
- `CHECK_CLI_PACKAGES`：自訂要檢查的套件清單（以空白分隔）。

docker-compose 範例：

```yaml
services:
  aiagent:
    environment:
      - CHECK_CLI_UPDATES=1
      - CHECK_CLI_PACKAGES="@openai/codex @google/gemini-cli @anthropic-ai/claude-code @vibe-kit/grok-cli"
```

範例輸出：

```text
[cli-check] Checking CLI updates for: @openai/codex @google/gemini-cli @anthropic-ai/claude-code @vibe-kit/grok-cli
[cli-check] Updates available for the following global CLIs:
  - @openai/codex: 1.2.3 -> 1.2.5
  - @google/gemini-cli: 0.8.0 -> 0.9.1

[cli-check] To update, run:
  npm i -g @openai/codex@latest
  npm i -g @google/gemini-cli@latest

[cli-check] Set CHECK_CLI_UPDATES=0 to disable this check at startup.
```

手動更新指令（容器內）：

```bash
npm i -g @openai/codex@latest @google/gemini-cli@latest @anthropic-ai/claude-code@latest @vibe-kit/grok-cli@latest
```

### AI 工具使用方式

進入容器後，可直接使用以下 AI CLI 工具：

#### Claude Code

```bash
claude chat                # 啟動對話模式
claude edit                # 進入編輯模式
cchelp                     # 使用預設指令聊天 (需先執行 setup-claude.sh)
cc                         # claude 的簡易別名
```

#### Gemini CLI

```bash
gemini chat                # 啟動對話模式
gchat                      # 使用預設指令聊天 (需先執行 setup-gemini.sh)
```

#### Codex CLI

```bash
codex                      # 啟動 OpenAI Codex CLI
cx                         # codex 的簡易別名 (需先執行 setup-codex.sh)
cxanalyze <file>           # 分析程式碼檔案
cxrefactor <file>          # 重構程式碼
cxexplain <file>           # 解釋程式碼
```

#### 其他工具

```bash
grok                                   # 啟動 Grok CLI
claude-code-spec-workflow              # 啟動規格/bug 工作流主指令 (已全域安裝)
npx -p @pimzino/claude-code-spec-workflow claude-spec-dashboard   # 啟動即時 Dashboard
ccusage --version                      # 查看 ccusage 版本
ccusage --help                         # 查看 ccusage 指令說明
```

#### Claude Code Spec Workflow 快速示例

```bash
# 在專案目錄建立 .claude 結構
claude-code-spec-workflow

# 建立 Steering 文件 (product.md / tech.md / structure.md)
claude /spec-steering-setup

# 建立新功能規格
/spec-create user-auth "User auth system"

# 執行第一個任務 (task 1)
/spec-execute 1 user-auth

# 啟動 Dashboard 進行可視化追蹤
npx -p @pimzino/claude-code-spec-workflow claude-spec-dashboard
```

可使用 `config/claude/setup-spec-workflow.sh` 腳本追加常用 alias：

```bash
bash ~/.claude/setup-spec-workflow.sh
spec-get-steering             # 載入 steering context
spec-get-spec feature-name    # 載入指定功能規格 context
spec-dash                     # 啟動 Dashboard
```

詳細使用方式請參考 `USAGE.md`。

### 進階設定

可於 `.env` 檔案自訂參數：

- `NODE_VERSION`：指定 Node.js 版本

- `CHECK_CLI_UPDATES`：是否在啟動時檢查 CLI 更新（1/0）。
- `CHECK_CLI_PACKAGES`：自訂需要檢查更新的 CLI 套件清單。

修改後請重新建構映像：

```bash
docker-compose build --no-cache
```
