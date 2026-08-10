# shellcheck shell=bash
# Rate-limit segment: label, used%, resets_at epoch, soften-window secs, window secs.
#
# Two ideas stacked on top of a bare percentage:
#   - Soften near reset: high usage is less alarming when the window is
#     about to reset anyway, so the color steps down one level inside the
#     soften window (red→yellow, yellow→dim).
#   - Pace: if usage is running ahead of the elapsed fraction of the window
#     (with a 10-point margin), you're on track to hit the cap before it
#     resets — flagged with a red ▲ independent of the level color.

sl_rl_segment() {
  local label=$1 pct=$2 resets_at=$3 soften=${4:-0} win=${5:-0}
  [ -z "$pct" ] && return
  local p=${pct%.*}; p=${p:-0}
  local rem=$(( resets_at - SL_NOW ))

  local c=$DIM
  if   [ "$p" -ge 80 ]; then c=$RED
  elif [ "$p" -ge 50 ]; then c=$YELLOW
  fi
  if [ "$rem" -gt 0 ] && [ "$rem" -le "$soften" ]; then
    if   [ "$c" = "$RED" ];    then c=$YELLOW
    elif [ "$c" = "$YELLOW" ]; then c=$DIM
    fi
  fi

  local pace=""
  if [ "$win" -gt 0 ] && [ "$rem" -gt 0 ] && [ "$rem" -lt "$win" ]; then
    local elapsed_pct=$(( (win - rem) * 100 / win ))
    [ "$p" -ge 30 ] && [ "$p" -gt $(( elapsed_pct + 10 )) ] && pace="▲"
  fi

  local t; t=$(sl_fmt_countdown "$resets_at")
  printf " %b%s:%s%%%b" "$c" "$label" "$p" "$RESET"
  [ -n "$pace" ] && printf "%b▲%b" "$RED" "$RESET"
  [ -n "$t" ] && printf "%b(%s)%b" "$DIM" "$t" "$RESET"
}
