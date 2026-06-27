#!/bin/bash
# A portable statusline for Claude Code.
# Shows: current directory, git branch (+dirty flag), model, context usage,
# token counts, and accumulated session cost.
#
# Claude Code pipes a JSON status blob into this script's stdin on every
# refresh; whatever the script prints to stdout becomes the status line.
#
# Install:
#   1. Save this file somewhere, e.g. ~/.claude/statusline.sh
#   2. chmod +x ~/.claude/statusline.sh
#   3. Add to ~/.claude/settings.json:
#        "statusLine": {
#          "type": "command",
#          "command": "/absolute/path/to/statusline.sh"
#        }
#
# Requires: bash, jq, awk, git (optional). Honors the NO_COLOR convention.

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // empty')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
TOTAL_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

if [ -n "${NO_COLOR:-}" ]; then
    CYAN=''; GREEN=''; YELLOW=''; RED=''; DIM=''; RESET=''
else
    CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; DIM='\033[2m'; RESET='\033[0m'
fi

# Current directory name (basename of the working dir)
DIR_NAME=$(basename "${DIR:-$PWD}")

# Git branch
BRANCH=""
if git -C "${DIR:-.}" rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git -C "${DIR:-.}" branch --show-current 2>/dev/null)
    [ -z "$BRANCH" ] && BRANCH=$(git -C "${DIR:-.}" rev-parse --short HEAD 2>/dev/null)
    DIRTY=""
    [ -n "$(git -C "${DIR:-.}" status --porcelain -uno 2>/dev/null | head -1)" ] && DIRTY="*"
    BRANCH="${BRANCH}${DIRTY}"
fi

# Context bar (color by usage)
if [ "$PCT" -ge 80 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 50 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

COST_FMT=$(printf '$%.2f' "$COST")

# Shorten model name for display
MODEL_SHORT=$(echo "$MODEL" | sed 's/ (.*//; s/Claude //; s/Opus/opus/; s/Sonnet/sonnet/; s/Haiku/haiku/')

# Build output
LINE="${CYAN}${DIR_NAME}${RESET}"
[ -n "$BRANCH" ] && LINE="$LINE ${DIM} ${BRANCH}${RESET}"
# Format token counts (e.g. 12k/200k)
if [ "$CTX_SIZE" -gt 0 ] 2>/dev/null; then
    TOKENS_K=$(awk "BEGIN {printf \"%.0f\", $TOTAL_TOKENS/1000}")
    CTX_K=$(awk "BEGIN {printf \"%.0f\", $CTX_SIZE/1000}")
    TOKEN_STR="${TOKENS_K}k/${CTX_K}k"
else
    TOKEN_STR=""
fi

LINE="$LINE  ${DIM}${MODEL_SHORT}${RESET}  ${BAR_COLOR}${PCT}%${RESET}"
[ -n "$TOKEN_STR" ] && LINE="$LINE ${DIM}(${TOKEN_STR})${RESET}"
LINE="$LINE ${DIM}${COST_FMT}${RESET}"

echo -e "$LINE"
