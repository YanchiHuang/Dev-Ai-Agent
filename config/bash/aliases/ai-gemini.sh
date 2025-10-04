# ai-gemini.sh - Aliases for Google Gemini CLI
# Group: AI / Gemini

alias gchat='gemini chat --instructions ~/.gemini/instructions.txt'
ggod() { _run_danger gemini --yolo "$@"; }
export -f ggod
