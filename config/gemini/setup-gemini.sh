#!/bin/bash
# Gemini CLI 全域設定快速初始化腳本

echo "🛠 初始化 Gemini CLI 全域設定..."

# 建立 alias 到 .bashrc
if ! grep -q "alias gchat" ~/.bashrc; then
    echo "alias gchat='gemini chat --instructions ~/.gemini/instructions.txt'" >> ~/.bashrc
    echo "✅ 已添加 gchat alias 到 .bashrc"
else
    echo "ℹ️  gchat alias 已存在於 .bashrc"
fi

# 重新載入 .bashrc
source ~/.bashrc

echo "🎉 Gemini CLI 設定完成！"
echo ""
echo "使用方式："
echo "  gemini chat --instructions ~/.gemini/instructions.txt"
echo "  或使用快速指令："
echo "  gchat"
echo ""
echo "設定檔位置："
echo "  - 全域設定: ~/.gemini/settings.json"
echo "  - 指示檔案: ~/.gemini/instructions.txt"
