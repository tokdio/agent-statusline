# shellcheck shell=bash
# Git identity: branch name + dirty/ahead/behind markers from ONE
# `git status --porcelain=v2 --branch` call, parsed by ONE awk. No `git
# diff`, no `git rev-list` — porcelain v2 already carries the ahead/behind
# counts and a dirty flag in its own header lines.
#
# Sets globals: branch (raw name, "-" if not a repo), branch_str (colored).

sl_git_status() {
  local cwd=$1
  branch=""; branch_str=""
  [ -z "$cwd" ] && return
  { [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; } || return

  local gs
  gs=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)
  local ab_a ab_b dirty
  read -r branch ab_a ab_b dirty < <(awk '
    $2=="branch.head" {b=$3}
    $2=="branch.ab"   {a=$3; c=$4}
    !/^#/ && NF        {d=1}
    END {print (b?b:"-"), (a?a:"+0"), (c?c:"-0"), (d?1:0)}
  ' <<<"$gs")

  # Name in identity color; the markers are STATES, so they get state colors.
  printf -v branch_str "%b%s%b" "$C_BRANCH" "$branch" "$RESET"
  [ "$dirty" = "1" ]  && printf -v branch_str "%s%b*%b"  "$branch_str" "$C_DIRTY"  "$RESET"
  [ "$ab_a" != "+0" ] && printf -v branch_str "%s%b↑%s%b" "$branch_str" "$C_AHEAD"  "${ab_a#+}" "$RESET"
  [ "$ab_b" != "-0" ] && printf -v branch_str "%s%b↓%s%b" "$branch_str" "$C_BEHIND" "${ab_b#-}" "$RESET"
}
