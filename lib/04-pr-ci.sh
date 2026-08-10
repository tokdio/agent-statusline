# shellcheck shell=bash
# shellcheck disable=SC2034  # ci_state/ci_stale are consumed by the entrypoint's row1_left()
# PR review-state icon (from the JSON payload, free) + CI rollup (from
# `gh pr checks`, NOT free — a real network round-trip). The CI check is
# read from a 120s file cache and refreshed in the background so it never
# blocks a render; the same cache-then-background-refresh shape is reused
# by 05-project-state.sh for Beads.

# Sets globals: ci_state, ci_stale
sl_pr_ci_status() {
  local root=$1 key=$2 pr_num=$3
  ci_state=""; ci_stale=""
  [ -n "$pr_num" ] && command -v gh >/dev/null 2>&1 || return

  local cache="$SL_CACHE_DIR/ci-$key-$pr_num"
  local age=999999
  if [ -f "$cache" ]; then
    ci_state=$(<"$cache")
    age=$(( SL_NOW - $(stat -f %m "$cache" 2>/dev/null || echo 0) ))
    [ "$age" -ge 120 ] && ci_stale="~"
  fi

  [ "$age" -ge 120 ] || return
  (
    cd "$root" || exit 1
    local result
    result=$(gh pr checks "$pr_num" --json bucket 2>/dev/null \
      | jq -r 'if length == 0 then "none"
               elif any(.[]; .bucket == "fail")    then "fail"
               elif any(.[]; .bucket == "pending") then "pending"
               else "pass" end' 2>/dev/null)
    if [ -n "$result" ]; then
      printf '%s' "$result" > "$cache.$$" && mv -f "$cache.$$" "$cache"
    else
      rm -f "$cache.$$"
    fi
  ) >/dev/null 2>&1 &
}
