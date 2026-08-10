# shellcheck shell=bash
# Row 3: project state read straight off disk — none of this comes from
# Claude Code's JSON payload. Each sl_proj_* function appends to the global
# $proj string and is a silent no-op when its source isn't present in the
# repo, so row 3 as a whole simply doesn't render on a plain repo.

# GSD: phase + status glyph + plan progress from .planning/STATE.md frontmatter.
sl_proj_gsd() {
  local root=$1
  [ -f "$root/.planning/STATE.md" ] || return

  local g_phase g_status g_done g_total
  read -r g_phase g_status g_done g_total < <(awk -F': ' '
    NR>30 {exit}
    {gsub(/^[ \t]+/, "", $1)}
    $1=="current_phase"   {p=$2}
    $1=="status"          {s=$2}
    $1=="completed_plans" {c=$2}
    $1=="total_plans"     {t=$2}
    END {print (p!=""?p:"-"), (s!=""?s:"-"), (c!=""?c:0), (t!=""?t:0)}
  ' "$root/.planning/STATE.md")

  local g_glyph g_color
  case "$g_status" in
    executing) g_glyph="▶"; g_color=$GREEN ;;
    complete*) g_glyph="✓"; g_color=$DIM ;;
    blocked*)  g_glyph="✗"; g_color=$RED ;;
    *)         g_glyph="◆"; g_color=$YELLOW ;;
  esac
  printf -v proj "%s%bgsd:%s %s%b" "$proj" "$g_color" "$g_phase" "$g_glyph" "$RESET"
  if [ "$g_total" -gt 0 ] 2>/dev/null; then
    printf -v proj "%s %b%s/%s%b" "$proj" "$DIM" "$g_done" "$g_total" "$RESET"
  fi
  # Paused work waiting to be resumed (written by pause-work, eaten by resume)
  [ -f "$root/.planning/HANDOFF.md" ] && printf -v proj "%s %bhandoff!%b" "$proj" "$C_HANDOFF" "$RESET"
}

# OpenSpec: active proposals split into not-started ("new") vs in-flight
# ("wip" — any [x] checked in tasks.md). "new" goes red at 3+, which is
# also the threshold the `em` fan-out orchestrator uses to decide whether a
# repo has enough queued work to justify a parallel worktree fan-out.
sl_proj_openspec() {
  local root=$1
  [ -d "$root/openspec/changes" ] || return

  local os_new=0 os_wip=0 d
  for d in "$root/openspec/changes"/*/; do
    [ -d "$d" ] || continue
    case "$d" in */archive/) continue ;; esac
    if [ -f "${d}tasks.md" ] && grep -q '\[x\]' "${d}tasks.md" 2>/dev/null; then
      os_wip=$((os_wip + 1))
    else
      os_new=$((os_new + 1))
    fi
  done
  [ $((os_new + os_wip)) -gt 0 ] || return

  printf -v proj "%s  %bos%b" "$proj" "$DIM" "$RESET"
  if [ "$os_new" -gt 0 ]; then
    local os_color=$GREEN
    [ "$os_new" -ge 3 ] && os_color=$RED
    printf -v proj "%s %bnew:%s%b" "$proj" "$os_color" "$os_new" "$RESET"
  fi
  [ "$os_wip" -gt 0 ] && printf -v proj "%s %bwip:%s%b" "$proj" "$YELLOW" "$os_wip" "$RESET"
}

# Beads: ready/in-progress/blocked from `bd stats`, cached — `bd` takes
# close to a second, far too slow to run inline on every render. Same
# cache-then-background-refresh shape as 04-pr-ci.sh's CI check.
sl_proj_beads() {
  local root=$1 key=$2
  [ -d "$root/.beads" ] && command -v bd >/dev/null 2>&1 || return

  local cache="$SL_CACHE_DIR/bds-$key"
  local bd_rdy="" bd_wip="" bd_blk="" age=999999
  if [ -f "$cache" ]; then
    read -r bd_rdy bd_wip bd_blk < "$cache"
    age=$(( SL_NOW - $(stat -f %m "$cache" 2>/dev/null || echo 0) ))
  fi
  if [ "$age" -ge 120 ]; then
    (
      cd "$root" || exit 1
      local result
      result=$(bd stats --json 2>/dev/null \
        | jq -r '.summary | "\(.ready_issues) \(.in_progress_issues) \(.blocked_issues)"' 2>/dev/null)
      if [ -n "$result" ]; then
        printf '%s' "$result" > "$cache.$$" && mv -f "$cache.$$" "$cache"
      else
        rm -f "$cache.$$"
      fi
    ) >/dev/null 2>&1 &
  fi

  case "$bd_rdy" in ''|*[!0-9]*) bd_rdy="" ;; esac  # first run / junk cache
  [ -n "$bd_rdy" ] && [ $((bd_rdy + ${bd_wip:-0} + ${bd_blk:-0})) -gt 0 ] || return

  printf -v proj "%s  %bbd%b" "$proj" "$DIM" "$RESET"
  [ "$bd_rdy" -gt 0 ] && printf -v proj "%s %bready:%s%b" "$proj" "$CYAN" "$bd_rdy" "$RESET"
  [ "${bd_wip:-0}" -gt 0 ] 2>/dev/null && printf -v proj "%s %bwip:%s%b" "$proj" "$YELLOW" "$bd_wip" "$RESET"
  [ "${bd_blk:-0}" -gt 0 ] 2>/dev/null && printf -v proj "%s %bblocked:%s%b" "$proj" "$RED" "$bd_blk" "$RESET"
  # ~ = serving a stale cache while a refresh runs in the background
  [ "$age" -ge 120 ] && printf -v proj "%s%b~%b" "$proj" "$DIM" "$RESET"
}
