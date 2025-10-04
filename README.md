# 🧠 Dev-Ai-Agent

多家 AI CLI 工具整合在同一個 Debian 容器，開箱即用的開發助手環境。

</div>

## 專案概要

Dev-Ai-Agent 以 `debian:bookworm-slim` 為基礎，建置一個非 root 的 `aiagent` 使用者環境，預載 Node.js 22、Python、GitHub CLI 與多個 AI/開發工具。透過 `docker-compose` 便能在任何機器快速取得一致的工作站，同時提供自動檢查 CLI 更新、SuperClaude 工作流、Spec-Kit、MCP 伺服器等整合能力。

### Codebase Summary

| 模組                                  | 內容                                                                                                        | 重點                                                                                                     |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `Dockerfile`                          | 三階段建置流程（`base-apt` → `builder` → `final`）安裝系統套件、NVM/Node、全域 npm CLI、`uv`、SuperClaude。 | 使用 cache mount 加速建構、建立 `aiagent` 使用者、在 runtime 階段載入 `entrypoint` 與 CLI 更新檢查腳本。 |
| `docker-compose.yml`                  | 啟動 `aiagent` 服務並掛載設定、workspace、SSH 金鑰。                                                        | 支援環境變數覆寫 Node 版本、CLI 更新策略與 API 金鑰。                                                    |
| `config/scripts/entrypoint.sh`        | 容器啟動時載入 NVM、執行 CLI 更新檢查後進入工作殼層。                                                       | 確保錯誤不會中斷啟動。                                                                                   |
| `config/scripts/check-cli-updates.sh` | 利用 `npm outdated -g --json` 檢查全域 CLI 版本，並可選擇自動更新。                                         | 支援環境變數 `CHECK_CLI_UPDATES`、`CLI_AUTO_UPDATE`、`CHECK_CLI_PACKAGES`。                              |
| `config/claude`                       | 提供 Claude Code 設定、預設指令、SuperClaude 安裝與 Spec Workflow alias 腳本。                              | `setup-SuperClaude.sh` 支援 pipx/uv/pip/npm 等安裝管道並產生日誌。                                       |
| `config/codex`                        | Codex CLI 的 `config.toml` 與初始化腳本。                                                                   | 預先配置多個 provider/profile（OpenAI、Ollama、vLLM 等）。                                               |
| `config/gemini`                       | Gemini CLI 設定檔與系統提示。                                                                               | 預載 MCP GitHub server 設定與繁體中文回應指示。                                                          |
| `.env.example`                        | 範例環境變數。                                                                                              | 說明 Node 版本、API 金鑰與 CLI 更新開關。                                                                |
| `USAGE.md`                            | 詳細操作手冊。                                                                                              | 包含建置、登入、工具使用、疑難排解、進階設定。                                                           |

> 上表涵蓋倉庫內所有主要檔案，更多細節可於對應路徑查看原始碼與腳本註解。

## 核心特色

- **多重 AI CLI**：`@anthropic-ai/claude-code`、`@openai/codex`、`@google/gemini-cli`、`@vibe-kit/grok-cli`、`@github/copilot` 皆已全域安裝，另含 `@pimzino/claude-code-spec-workflow`、`ccusage`。
- **自動化工作流**：內建 SuperClaude Framework 安裝腳本與 Spec Workflow 別名，快速啟用規格驅動開發。
- **安全與一致性**：使用非 root 使用者、固定 UID/GID=1000，預掛載 `config/`、`workspace/`、`projects` 以保存設定與成果。
- **啟動檢查機制**：容器啟動時自動檢查全域 CLI 是否過期，可選擇自動更新或僅提示更新指令。
- **可擴充設計**：支援自訂 Node 版本、環境變數與 MCP server；利用 `config/` 目錄調整各 CLI 的 instructions/config。

## 目錄結構

```text
.
├── Dockerfile                # 多階段建置與工具安裝腳本
├── docker-compose.yml        # 容器服務、掛載與環境變數定義
├── .env.example              # 範例環境設定
├── USAGE.md                  # 詳細使用指南
├── config/
│   ├── scripts/              # 入口腳本與 CLI 更新檢查
│   ├── claude/               # Claude Code、SuperClaude、Spec Workflow 設定
│   ├── gemini/               # Gemini CLI 設定與系統提示
│   ├── codex/                # Codex CLI profiles 與初始化腳本
│   ├── gitconfig             # 預設 Git 設定
│   └── ssh/                  # 掛載用 SSH 金鑰資料夾
└── workspace/                # 與主機同步的開發目錄
```

## 快速開始

1. **準備環境變數**

   ```bash
   cp .env.example .env
   # 編輯 .env 並填入 OPENAI_API_KEY、GEMINI_API_KEY、ANTHROPIC_API_KEY 等金鑰
   ```

2. **建置並啟動容器**

   ```bash
   docker-compose up -d
   ```

3. **進入工作空間**

   ```bash
   docker-compose exec aiagent bash
   ```

4. **（可選）設定常用別名**

   ```bash
   bash ~/.claude/setup-claude.sh
   bash ~/.gemini/setup-gemini.sh
   bash ~/.codex/setup-codex.sh
   bash ~/.claude/setup-spec-workflow.sh   # 啟用 Spec Workflow 快捷指令
   bash config/scripts/setup-copilot-godmode.sh  # 啟用 ctgod（Copilot --allow-all-tools，請確認環境安全）
   ```

更多指令（重新建置、關閉容器等）請參考 [USAGE.md](USAGE.md)。

## 環境變數與設定

| 變數                                                      | 預設值           | 說明                                                                  |
| --------------------------------------------------------- | ---------------- | --------------------------------------------------------------------- |
| `NODE_VERSION`                                            | `22`             | 建置時安裝的 Node.js 版本，可在 `.env` 或 `docker-compose.yml` 覆寫。 |
| `OPENAI_API_KEY` / `GEMINI_API_KEY` / `ANTHROPIC_API_KEY` | `""`             | 各 CLI 所需的 API 金鑰。                                              |
| `CLAUDE_CODE_MODEL` / `OPENAI_MODEL` / `GEMINI_MODEL`     | `""`             | (可選) 指定各 AI 工具使用的模型。                                     |
| `TZ`                                                      | `UTC`            | 設定容器的時區，例如 `Asia/Taipei`。                                  |
| `CHECK_CLI_UPDATES`                                       | `1`              | 啟動時是否檢查全域 CLI 更新 (1=啟用, 0=停用)。                      |
| `CLI_AUTO_UPDATE`                                         | `0`              | 是否在啟動時自動更新過期的 CLI (1=啟用, 0=停用)。                    |
| `CHECK_CLI_PACKAGES`                                      | _(空白分隔字串)_ | 自訂要檢查的套件清單。                                                |
| `GH_TOKEN`                                                | `""`             | GitHub Copilot CLI 使用的 PAT，適合在無瀏覽器環境登入。               |
| `COPILOT_MODEL`                                           | `""`             | 指定 Copilot CLI 預設模型（視 CLI 版本支援情況）。                    |

> 建議不要將 `.env` 檔案提交至版本控制，避免洩漏金鑰。可利用 `docker-compose` 的 `environment` 欄位或 CI 秘密管理服務提供變數。

## 開發環境建議

為了獲得最佳的開發體驗，建議在 VS Code 中安裝以下擴充套件。這些建議已包含在 `.vscode/extensions.json` 中，當您用 VS Code 開啟此專案時，右下角會自動提示安裝。

- **Docker**: `ms-azuretools.vscode-docker` - 管理容器與映像檔。
- **YAML**: `redhat.vscode-yaml` - 編輯 `docker-compose.yml` 的好幫手。
- **Git**: `eamodio.gitlens` - 強大的 Git 可視化工具。
- **AI 助理**:
  - `github.copilot` & `github.copilot-chat`
  - `anthropic.claude-code`
  - `Google.geminicodeassist`
- **程式碼品質與格式化**:
  - `esbenp.prettier-vscode` - 自動格式化。
  - `dbaeumer.vscode-eslint` - 語法檢查。
- **其他實用工具**:
  - `vscode-icons-team.vscode-icons` - 美化檔案總管的圖示。
  - `usernamehw.errorlens` - 將錯誤與警告直接顯示在程式碼行。

## 啟動時的 CLI 版本檢查

容器啟動時，`entrypoint.sh` 會呼叫 `check-cli-updates.sh`：

1. 解析 `CHECK_CLI_PACKAGES`（預設包含 Codex、Gemini、Claude Code、Grok、Copilot）。
2. 執行 `npm outdated -g` 判斷版本差異，失敗時不阻斷啟動。
3. 若偵測到更新，顯示建議指令；當 `CLI_AUTO_UPDATE=1` 時，自動執行 `npm i -g <pkg>@latest`。

## AI 工具速覽

| 工具               | 指令                                     | 補充                                                                                                                                                          |
| ------------------ | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Claude Code        | `claude`, `claude chat`, `claude edit`   | 手動執行 `~/.claude/setup-claude.sh` 後會加入 `cc`, `cchelp`, `cskip`, `ccgod` 等 alias；`cskip`/`ccgod` 會跳過安全檢查，僅在可完全信任的倉庫使用。           |
| Gemini CLI         | `gemini`, `gemini chat`                  | 手動執行 `~/.gemini/setup-gemini.sh` 後會建立 `gchat`, `ggod` 等別名；`ggod` 會以 `--yolo` 模式繞過確認，請特別留意執行風險。                                 |
| Codex CLI          | `codex`, `codex --profile <name>`        | `config.toml` 已定義 OpenAI、Ollama、vLLM 等 profiles；執行 `~/.codex/setup-codex.sh` 會加入 `cx`, `cxgod` 等 alias，其中 `cxgod` 會略過 sandbox 與審核程序。 |
| Grok CLI           | `grok`                                   | 由 Dockerfile 全域安裝，可直接對話。                                                                                                                          |
| GitHub Copilot CLI | `copilot chat`, `copilot suggest`        | 建議預先設定 `GH_TOKEN` 以利無頭環境登入。                                                                                                                    |
| Spec Workflow      | `claude-code-spec-workflow`, `spec-dash` | 透過 `setup-spec-workflow.sh` 追加 `spec-get-steering` 等 alias，搭配 `npx ... claude-spec-dashboard`。                                                       |

## Git 與資料持久化

本專案透過兩種方式實現資料持久化，確保您的工作成果和設定不會因容器停止而遺失：

- **`workspace/` (同步目錄)**: 這是您的主要開發目錄，它會**即時**與主機上的 `workspace/` 資料夾雙向同步。適合放置您希望在主機上使用 IDE 或編輯器直接存取的專案檔案。

- **`projects` (具名資料卷)**: 這是一個由 Docker 管理的具名資料卷 (named volume)，掛載於容器內的 `/home/aiagent/projects`。它適合用來存放不需要在主機上頻繁直接編輯，但希望在不同專案或容器生命週期之間長期保存的資料，例如大型資料集、測試成品或次要專案。

- **`config/` (設定檔掛載)**: 所有 `config/` 目錄下的設定檔會分別掛載至容器內對應的家目錄路徑 (例如 `~/.claude`, `~/.gemini`)。這讓您可以直接在主機上版本控制所有 AI 工具的設定。

- **Git 設定**: 預設的 Git 設定 (`user.name`, `user.email`) 可在容器內隨時透過 `git config --global` 指令覆寫。

## 疑難排解與延伸閱讀

- 常見操作（重新建置、進入容器、檢查日誌、權限處理、API 金鑰問題、網路檢查）請參考 [USAGE.md](USAGE.md)。
- 若要手動更新全域 CLI，可直接參考並執行 repo 中的檢查與更新腳本（config/scripts/check-cli-updates.sh）。該腳本會根據 CHECK_CLI_PACKAGES 檢查版本差異，並在設定 CLI_AUTO_UPDATE=1 時自動執行更新。範例：

  - 在容器內執行檢查並（可選）自動更新：

    ```bash
    # 只檢查
    docker-compose exec aiagent bash -lc "config/scripts/check-cli-updates.sh"

    # 自動更新（在執行前可先設定環境變數）
    docker-compose exec aiagent bash -lc "export CLI_AUTO_UPDATE=1 && config/scripts/check-cli-updates.sh"
    ```

  - 或直接手動更新指定套件：

    ```bash
    npm i -g @openai/codex@latest @google/gemini-cli@latest \
      @anthropic-ai/claude-code@latest @vibe-kit/grok-cli@latest @github/copilot@latest
    ```

- SuperClaude 安裝日誌位於 `~/superclaude_install.log`，失敗時可在該檔案查詢原因。

歡迎將 Dev-Ai-Agent 作為 AI 助手或自動化開發環境的基礎，依需求擴充更多 CLI、腳本與服務！

## 模組化 Alias 框架

本專案提供一個可選的「模組化 alias & 函式載入系統」，避免在 `~/.bashrc` 中堆疊大量重複腳本。特色：

- 分類管理：AI CLI (`ai-claude.sh`, `ai-codex.sh`, `ai-gemini.sh`, `ai-copilot.sh`)、`git`、`docker`、`system`、`custom`。
- 安全包裹：具破壞性或繞過安全檢查的指令改為函式，執行前互動確認（`ccgod`, `cxgod`, `ctgod`, `ggod`）。
- 輕量安裝 / 可卸載：`setup-aliases.sh` / `uninstall-aliases.sh`。
- 工具狀態：`ai_cli_status` 顯示可用 CLI 與版本資訊。
- 檔案追蹤：`aliases_sources` 可看哪些檔案被載入。
- 搜尋支援：`aliases_find <pattern>` 模糊搜尋（若安裝 `fzf` 會啟動互動選單）。

### 安裝

```bash
bash config/scripts/setup-aliases.sh
source ~/.bashrc
```

執行後 `~/.bashrc` 會新增一段標記區塊：

```bash
# >>> managed-alias-framework >>>
# Load modular alias framework
if [ -f "$HOME/.config/bash/init.sh" ]; then
   . "$HOME/.config/bash/init.sh"
fi
# <<< managed-alias-framework <<<
```

### 目錄結構（安裝後於使用者家目錄）

```text
~/.config/bash/
├── init.sh
├── aliases/
│   ├── ai-claude.sh
│   ├── ai-codex.sh
│   ├── ai-copilot.sh
│   ├── ai-gemini.sh
│   ├── git.sh
│   ├── docker.sh
│   ├── system.sh
│   └── custom.sh
└── functions/
      ├── alias-framework.sh
      └── ai-codex-functions.sh
```

### 常用指令

| 指令                                 | 功能                                     |
| ------------------------------------ | ---------------------------------------- |
| `ai_cli_status`                      | 顯示 AI CLI 安裝狀態與版本               |
| `aliases_list [regex]`               | 列出全部或符合過濾的 alias               |
| `aliases_find <keyword>`             | 搜尋 alias（有 `fzf` 進入互動模式）      |
| `aliases_sources`                    | 顯示實際載入的檔案清單                   |
| `aliases_doc [-m] [-o file]`         | 導出目前 alias 文件（純文字或 Markdown） |
| `ccgod` / `cxgod` / `ctgod` / `ggod` | 危險操作，執行前會要求二次確認           |

`aliases_doc` 範例：

```bash
# 螢幕輸出純文字
aliases_doc

# 輸出 Markdown 到檔案
aliases_doc -m -o ~/ALIAS_DOC.md
```

### 卸載

```bash
bash config/scripts/uninstall-aliases.sh
```

### 客製化建議

1. 自訂 alias 放在 `custom.sh`。
2. 停用某一組 alias：把檔案改名為 `*.disabled` 或移出 `aliases/`。
3. 新增新功能：在 `functions/` 下放置 `xxx.sh`，自動被載入。
4. 想加速大量 alias：可用 `alias gen_<name>() { ... }` 搭配腳本產生。
