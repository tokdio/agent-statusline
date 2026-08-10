# shellcheck shell=bash
# shellcheck disable=SC2034  # every var here is consumed by sibling lib files and the entrypoint, not this one
# Base palette + 256-color identity palette for the statusline.
#
# Populates on call:
#   CYAN GREEN YELLOW RED MAGENTA DIM RESET          — base, semantic (status)
#   C_PATH C_BRANCH C_DIRTY C_AHEAD C_BEHIND C_WT     — row-1 identity/state
#   C_SESS C_HANDOFF C_FAST
#   C_EFF_MED C_EFF_HIGH C_EFF_MAX C_COST_WARN C_COST_HOT
#   M_FABLE M_OPUS M_SONNET M_HAIKU                   — per-model identity hue
#
# green/yellow/red are reserved for STATUS (ok/warn/danger) everywhere else
# in the script, so identity fields (path, branch name, model, session) get
# their own 256-color hues instead of borrowing from the status palette.

sl_colors_init() {
  CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
  RED='\033[0;31m';  MAGENTA='\033[0;35m'; DIM='\033[2m'; RESET='\033[0m'

  # Falls back to the base palette only when TERM affirmatively reports
  # <256 colors — the statusline's env usually has no usable TERM at all,
  # so the 256-color branch below is what actually runs in practice.
  if [ -n "$TERM" ] && [ "$(tput colors 2>/dev/null || echo 256)" -lt 256 ]; then
    C_PATH=$CYAN;   C_BRANCH=$GREEN;  C_DIRTY=$YELLOW
    C_AHEAD=$GREEN; C_BEHIND=$RED;    C_WT=$MAGENTA
    C_SESS=$DIM;    C_HANDOFF=$RED;   C_FAST=$CYAN
    C_EFF_MED=$CYAN; C_EFF_HIGH=$YELLOW; C_EFF_MAX=$RED
    C_COST_WARN=$YELLOW; C_COST_HOT=$RED
    M_FABLE=$YELLOW; M_OPUS=$YELLOW; M_SONNET=$YELLOW; M_HAIKU=$YELLOW
  else
    C_PATH='\033[38;5;81m';    C_BRANCH='\033[38;5;140m'; C_DIRTY='\033[38;5;220m'
    C_AHEAD='\033[38;5;114m';  C_BEHIND='\033[38;5;203m'; C_WT='\033[38;5;175m'
    C_SESS='\033[38;5;110m';   C_HANDOFF='\033[1;38;5;203m'; C_FAST='\033[38;5;123m'
    C_EFF_MED='\033[38;5;75m'; C_EFF_HIGH='\033[38;5;214m'; C_EFF_MAX='\033[38;5;203m'
    C_COST_WARN='\033[38;5;220m'; C_COST_HOT='\033[38;5;208m'
    M_FABLE='\033[38;5;141m'; M_OPUS='\033[38;5;208m'
    M_SONNET='\033[38;5;75m'; M_HAIKU='\033[38;5;114m'
  fi
}
