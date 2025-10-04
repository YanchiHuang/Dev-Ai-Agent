#!/bin/bash
# ===============================================
# SuperClaude Framework 安裝腳本
# 適用環境：Linux / Docker 容器
# 作者：Yanchi Huang
# ===============================================

set -euo pipefail

LOG_FILE="$HOME/superclaude_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== SuperClaude 安裝開始 $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="

# ====== 參數設定 ======
INSTALL_DIR="$HOME/superclaude"
REPO_URL="https://github.com/SuperClaude-Org/SuperClaude_Framework.git"
PROFILE=${SUPERCLAUDE_PROFILE:-developer}  # 可改成 default / developer / 其他自訂
VENV_DIR=".venv"

# 安裝方式 (優先讀取環境變數 SUPERCLAUDE_INSTALLER)
# 可選: pipx | uv | pip | npm
INSTALLER=${SUPERCLAUDE_INSTALLER:-uv}
echo "選擇安裝方式: $INSTALLER"

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

case "$INSTALLER" in
    pipx)
        echo "[3/5] 使用 pipx 安裝 (官方推薦) ..."
        python3 -m pip install --upgrade pip wheel setuptools >/dev/null 2>&1 || true
        python3 -m pip install --upgrade pipx || true
        export PATH="$HOME/.local/bin:$PATH"
        if ! command -v pipx >/dev/null 2>&1; then
            echo "❌ pipx 未安裝成功"; exit 3; fi
        pipx install --force SuperClaude || { echo "pipx install 失敗"; exit 4; }
        ;;
    uv)
        echo "[3/5] 使用 uv 安裝..."
        if ! curl -Ls https://astral.sh/uv/install.sh | sh; then
            echo "⚠️ uv 安裝失敗，回退 pip"; INSTALLER=pip; fi
        if [ "$INSTALLER" = uv ]; then
            export PATH="$HOME/.local/bin:$PATH"
            uv venv || { echo "uv venv 失敗, 回退 pip"; INSTALLER=pip; }
            if [ "$INSTALLER" = uv ]; then
                . "$VENV_DIR/bin/activate"
                uv pip install --no-cache SuperClaude || { echo "uv pip 失敗, 回退 pip"; deactivate || true; INSTALLER=pip; }
            fi
        fi
        if [ "$INSTALLER" = pip ]; then
            echo "改用 pip 安裝..."; python3 -m venv "$VENV_DIR"; . "$VENV_DIR/bin/activate"; python3 -m pip install --upgrade pip wheel setuptools; pip install --no-cache-dir SuperClaude; fi
        ;;
    pip)
        echo "[3/5] 使用 pip 建立虛擬環境..."
        python3 -m venv "$VENV_DIR"
        . "$VENV_DIR/bin/activate"
        python3 -m pip install --upgrade pip wheel setuptools
        pip install --no-cache-dir SuperClaude
        ;;
    npm)
        echo "[3/5] 使用 npm 全域安裝..."
        if ! command -v npm >/dev/null 2>&1; then echo "❌ npm 不存在"; exit 5; fi
        npm install -g @bifrost_inc/superclaude || { echo "npm 安裝失敗"; exit 6; }
        ;;
    *)
        echo "未知安裝方式: $INSTALLER"; exit 7;;
esac

# ====== 執行安裝程序 ======
echo "[4/5] 執行 SuperClaude 安裝程序..."
echo "[4/5] 檢測是否支援 --profile 參數..."
PROFILE_SUPPORTED=false
if ( [ "$INSTALLER" = npm ] && superclaude install --help 2>&1 | grep -q -- '--profile' ) || \
     ( [ "$INSTALLER" != npm ] && python3 -m SuperClaude install --help 2>&1 | grep -q -- '--profile' ); then
    PROFILE_SUPPORTED=true
    echo "偵測到支援 --profile，將使用: $PROFILE"
else
    echo "未偵測到 --profile 支援，將略過該參數"
fi

if [ "$INSTALLER" = npm ]; then
    echo "[4/5] 執行 superclaude install (npm 安裝模式)..."
    if $PROFILE_SUPPORTED; then
        if ! superclaude install --profile "$PROFILE" --yes; then echo "❌ superclaude install 失敗"; exit 2; fi
    else
        if ! superclaude install --yes; then echo "❌ superclaude install 失敗"; exit 2; fi
    fi
else
    echo "[4/5] 執行 python -m SuperClaude install ..."
    if [ -f "$VENV_DIR/bin/activate" ]; then . "$VENV_DIR/bin/activate"; fi
    if $PROFILE_SUPPORTED; then
        if ! python3 -m SuperClaude install --profile "$PROFILE" --yes; then echo "❌ SuperClaude install 子指令失敗" >&2; exit 2; fi
    else
        if ! python3 -m SuperClaude install --yes; then echo "❌ SuperClaude install 子指令失敗" >&2; exit 2; fi
    fi
fi

# ====== 安裝完成確認 ======
echo "[5/5] 驗證安裝結果..."
if command -v superclaude >/dev/null 2>&1; then
    echo -n "superclaude 版本: "
    superclaude --version || echo "⚠️ 版本查詢失敗"
else
    echo "⚠️ 無法直接執行 superclaude（未加入 PATH 或安裝失敗）"
fi

echo "✅ SuperClaude Framework 安裝完成！"
echo "=== SuperClaude 安裝結束 $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="
