#!/bin/bash
# ===============================================
# SuperClaude Framework 安裝腳本
# 適用環境：Linux / Docker 容器
# 作者：Yanchi Huang
# ===============================================

set -e  # 若有錯誤立即停止
set -o pipefail

# ====== 參數設定 ======
INSTALL_DIR="$HOME/superclaude"
REPO_URL="https://github.com/SuperClaude-Org/SuperClaude_Framework.git"
USE_UV=true     # 設為 false 則使用 pip
PROFILE="developer"  # 可改成 default / developer / 其他自訂
VENV_DIR=".venv"

# ====== 安裝系統相依套件 ======
# echo "[1/5] 安裝必要套件..."
# apt-get update
# apt-get install -y --no-install-recommends git curl python3 python3-venv python3-pip
# rm -rf /var/lib/apt/lists/*

# ====== 下載專案 ======
echo "[2/5] 下載 SuperClaude Framework 專案..."
mkdir -p "$INSTALL_DIR"
if [ ! -d "$INSTALL_DIR/.git" ]; then
    git clone "$REPO_URL" "$INSTALL_DIR"
else
    echo "已有 Git 專案，執行更新..."
    git -C "$INSTALL_DIR" pull
fi

cd "$INSTALL_DIR"

# ====== 安裝 uv 或使用 pip ======
if [ "$USE_UV" = true ]; then
    echo "[3/5] 安裝 uv 並建立虛擬環境..."
    curl -Ls https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    uv venv
    . "$VENV_DIR/bin/activate"
    uv pip install SuperClaude
else
    echo "[3/5] 使用 pip 建立虛擬環境..."
    python3 -m venv "$VENV_DIR"
    . "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install SuperClaude
fi

# ====== 執行安裝程序 ======
echo "[4/5] 執行 SuperClaude 安裝程序..."
python3 -m SuperClaude install --profile "$PROFILE" --yes

# ====== 安裝完成確認 ======
echo "[5/5] 驗證安裝結果..."
superclaude --version || echo "⚠️ 無法直接執行 superclaude，請確認 PATH 設定"

echo "✅ SuperClaude Framework 安裝完成！"
