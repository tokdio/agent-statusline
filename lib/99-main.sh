# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154  # SL_NOW/ci_state/ci_stale/model_col are set by sibling modules — only meaningful once build.sh flattens this file after them
# Composition root: parses the JSON payload and decides what goes on each
# row. Everything above this file in lib/ is a reusable helper with no
# knowledge of the payload shape; this is the only file that reads it.
set -o pipefail

SL_CACHE_DIR="$HOME/.cache/claude-statusline"
mkdir -p "$SL_CACHE_DIR" 2>/dev/null
SL_NOW=$(date +%s)

input=$(cat)
# Debug: keep last real payload for inspection (tiny; overwritten each run)
printf '%s' "$input" > "$SL_CACHE_DIR/last-input.json" 2>/dev/null

# One jq call: all fields joined with the ASCII unit separator (\x1f).
# NOT @tsv: tab is IFS whitespace, so bash `read` collapses empty middle
# fields; \x1f is non-whitespace and preserves them.
IFS=$'\x1f' read -r cwd model in_tok out_tok lines_add lines_rem ctx ctx_size style \
  sess_name effort fast rl5 rl5_reset rl7 rl7_reset wt gwt pr_num pr_url pr_state \
  dur_ms cost_usd x200k repo_host repo_owner repo_name \
  cur_in cache_rd cache_cr api_ms think < <(
  printf '%s' "$input" | jq -r '[
    .cwd // "",
    .model.display_name // "",
    .context_window.total_input_tokens // 0,
    .context_window.total_output_tokens // 0,
    .cost.total_lines_added // 0,
    .cost.total_lines_removed // 0,
    .context_window.remaining_percentage // "",
    .context_window.context_window_size // 0,
    .output_style.name // "",
    .session_name // "",
    .effort.level // "",
    (.fast_mode // false),
    .rate_limits.five_hour.used_percentage // "",
    .rate_limits.five_hour.resets_at // 0,
    .rate_limits.seven_day.used_percentage // "",
    .rate_limits.seven_day.resets_at // 0,
    .worktree.name // "",
    .workspace.git_worktree // "",
    .pr.number // "",
    .pr.url // "",
    .pr.review_state // "",
    .cost.total_duration_ms // 0,
    .cost.total_cost_usd // "",
    (.exceeds_200k_tokens // false),
    .workspace.repo.host // "",
    .workspace.repo.owner // "",
    .workspace.repo.name // "",
    .context_window.current_usage.input_tokens // 0,
    .context_window.current_usage.cache_read_input_tokens // 0,
    .context_window.current_usage.cache_creation_input_tokens // 0,
    .cost.total_api_duration_ms // 0,
    (.thinking.enabled // false)
  ] | map(tostring) | join("\u001f")' 2>/dev/null
)

# Harden numerics against a failed/partial jq parse
in_tok=${in_tok:-0}; out_tok=${out_tok:-0}
lines_add=${lines_add:-0}; lines_rem=${lines_rem:-0}
ctx_size=${ctx_size:-0}; rl5_reset=${rl5_reset:-0}; rl7_reset=${rl7_reset:-0}
dur_ms=${dur_ms:-0}
cur_in=${cur_in:-0}; cache_rd=${cache_rd:-0}; cache_cr=${cache_cr:-0}; api_ms=${api_ms:-0}

sl_colors_init
short_cwd=$(sl_fmt_short_cwd "$cwd")
sl_git_status "$cwd"

total_tok=$(( in_tok + out_tok ))
tok_str=$(sl_fmt_humanize "$total_tok")

# Threshold-colored ctx% (remaining), only once the API has reported it
if [ -n "$ctx" ]; then
  ctx_int=${ctx%.*}; ctx_int=${ctx_int:-0}
  if   [ "$ctx_int" -gt 50 ]; then ctx_color=$GREEN
  elif [ "$ctx_int" -ge 20 ]; then ctx_color=$YELLOW
  else                              ctx_color=$RED
  fi
fi

sl_model_badge "$model" "$effort" "$fast" "$think"

# Worktree: --worktree session name, else any linked-worktree name
wt_name="${wt:-$gwt}"

# Project state ─ gsd phase · openspec proposals · beads ready — built into
# $proj (real ESC bytes via %b, printed with %s) and appended to row 3.
proj=""
root=""
[ -n "$branch_str" ] && root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
[ -z "$root" ] && root="$cwd"
key=$(printf '%s' "$root" | cksum); key=${key%% *}

sl_proj_gsd "$root"
sl_proj_openspec "$root"
sl_proj_beads "$root" "$key"
sl_pr_ci_status "$root" "$key" "$pr_num"

# ── Row 1: place ─ path (branch) ⎇worktree #PR ci @session … up:/cost right ──
row1_left() {
  if [ -n "$short_cwd" ]; then
    printf "%b%s%b" "$C_PATH" "$(sl_link "file://$cwd" "$short_cwd")" "$RESET"
  fi
  if [ -n "$branch_str" ]; then
    if [ -n "$repo_host" ] && [ -n "$branch" ] && [ "$branch" != "-" ]; then
      printf " %b(%b%s%b)%b" "$DIM" "$RESET" \
        "$(sl_link "https://$repo_host/$repo_owner/$repo_name/tree/$branch" "$branch_str")" "$DIM" "$RESET"
    else
      printf " %b(%b%s%b)%b" "$DIM" "$RESET" "$branch_str" "$DIM" "$RESET"
    fi
  fi
  [ -n "$wt_name" ] && printf " %b⎇ %s%b" "$C_WT" "$wt_name" "$RESET"
  if [ -n "$pr_num" ]; then
    local pr_icon pr_color
    case "$pr_state" in
      approved)          pr_icon="✓"; pr_color=$GREEN ;;
      changes_requested) pr_icon="✗"; pr_color=$RED ;;
      draft)              pr_icon="◐"; pr_color=$DIM ;;
      pending)            pr_icon="●"; pr_color=$YELLOW ;;
      *)                  pr_icon="";  pr_color=$MAGENTA ;;
    esac
    printf " %b%s%b" "$pr_color" "$(sl_link "$pr_url" "#$pr_num$pr_icon")" "$RESET"
    case "$ci_state" in
      fail)    printf " %bci:x%s%b" "$RED" "$ci_stale" "$RESET" ;;
      pending) printf " %bci:~%s%b" "$YELLOW" "$ci_stale" "$RESET" ;;
      pass)    printf " %bci:ok%s%b" "$GREEN" "$ci_stale" "$RESET" ;;
    esac
  fi
  [ -n "$sess_name" ] && printf " %b@%s%b" "$C_SESS" "$sess_name" "$RESET"
}

r1_col=""; r1_txt=""
dur_str=$(sl_fmt_span $(( dur_ms / 1000 )))
if [ -n "$dur_str" ]; then
  r1_txt="up:$dur_str"
  printf -v r1_col "%bup:%s%b" "$DIM" "$dur_str" "$RESET"
  # Busy ratio: api_duration / wall-clock duration = % of the session the
  # model spent working (thinking/generating/tools) vs idle waiting on me.
  # ~90%+ = autonomous grind; ~20% = mostly me reading/typing between turns.
  if [ "$api_ms" -gt 0 ] && [ "$dur_ms" -gt 0 ]; then
    api_pct=$(( api_ms * 100 / dur_ms ))
    r1_txt="$r1_txt api:$api_pct%"
    printf -v r1_col "%s %bapi:%s%%%b" "$r1_col" "$DIM" "$api_pct" "$RESET"
  fi
fi
if [ -n "$cost_usd" ]; then
  cost_str=$(printf '$%.2f' "$cost_usd" 2>/dev/null)
  if [ -n "$cost_str" ] && [ "$cost_str" != "\$0.00" ]; then
    # Cost is a status, not trivia: dim <$10, yellow <$30, orange above —
    # plus burn rate once the session is >5 min old
    cost_int=${cost_usd%%.*}; cost_int=${cost_int:-0}
    ccol=$DIM
    if   [ "$cost_int" -ge 30 ] 2>/dev/null; then ccol=$C_COST_HOT
    elif [ "$cost_int" -ge 10 ] 2>/dev/null; then ccol=$C_COST_WARN
    fi
    rate_str=""
    if [ "$dur_ms" -ge 300000 ]; then
      cents=${cost_str#\$}; cents=${cents/./}
      rate=$(( cents * 36000 / dur_ms ))
      [ "$rate" -ge 1 ] && rate_str="~\$$rate/h"
    fi
    r1_txt="${r1_txt:+$r1_txt }$cost_str${rate_str:+($rate_str)}"
    printf -v r1_col "%s%b%s%b" "${r1_col:+$r1_col }" "$ccol" "$cost_str" "$RESET"
    [ -n "$rate_str" ] && printf -v r1_col "%s%b(%s)%b" "$r1_col" "$DIM" "$rate_str" "$RESET"
  fi
fi
sl_row_print "$(row1_left)" "$r1_col" "$r1_txt"

# ── Row 2: session ─ model tokens ctx limits [style] … diffstat right-aligned ──
row2_left() {
  [ -n "$model_short" ] && printf '%s' "$model_col"
  # ctx as used/window (free%) — one unambiguous segment instead of tok + ctx%
  if [ -n "$ctx" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null; then
    used_tok=$(( ctx_size - ctx_size * ctx_int / 100 ))
    printf " %bctx:%b%b%s%b%b/%s%b" "$DIM" "$RESET" "$ctx_color" \
      "$(sl_fmt_humanize "$used_tok")" "$RESET" "$DIM" "$(sl_fmt_humanize "$ctx_size")" "$RESET"
    printf " %b(%b%b%s%%%b%b free)%b" "$DIM" "$RESET" "$ctx_color" "$ctx_int" "$RESET" "$DIM" "$RESET"
  elif [ "$total_tok" -gt 0 ]; then
    printf " %b%s tok%b" "$DIM" "$tok_str" "$RESET"
  fi
  [ "$x200k" = "true" ] && printf " %b!200k%b" "$RED" "$RESET"
  sl_rl_segment "5h" "$rl5" "$rl5_reset" 1800 18000
  sl_rl_segment "7d" "$rl7" "$rl7_reset" 43200 604800
  # Prompt-cache hit rate of the LAST request: cache_read / total input.
  # Dim while healthy (>=80%), yellow below, red <50% — a cold cache means
  # the request paid full price (~10x) instead of reading cached prefix.
  cache_tot=$(( cur_in + cache_rd + cache_cr ))
  if [ "$cache_tot" -gt 0 ]; then
    cache_pct=$(( cache_rd * 100 / cache_tot ))
    cc=$DIM
    if   [ "$cache_pct" -lt 50 ]; then cc=$RED
    elif [ "$cache_pct" -lt 80 ]; then cc=$YELLOW
    fi
    printf " %bcache:%s%%%b" "$cc" "$cache_pct" "$RESET"
  fi
  [ -n "$style" ] && [ "$style" != "default" ] && printf " %b[%s]%b" "$MAGENTA" "$style" "$RESET"
}

r2_col=""; r2_txt=""
if [ "$lines_add" -gt 0 ] || [ "$lines_rem" -gt 0 ]; then
  printf -v r2_col "%blines%b " "$DIM" "$RESET"
  printf -v r2_col "%s%b+%s%b" "$r2_col" "$GREEN" "$lines_add" "$RESET"
  printf -v r2_col "%s%b/%b"   "$r2_col" "$DIM" "$RESET"
  printf -v r2_col "%s%b-%s%b" "$r2_col" "$RED" "$lines_rem" "$RESET"
  r2_txt="lines +$lines_add/-$lines_rem"
fi
sl_row_print "$(row2_left)" "$r2_col" "$r2_txt"

# ── Row 3: project state (only when the repo has any) ──
proj="${proj# }"
[ -n "$proj" ] && printf '%s\n' "$proj"
exit 0
