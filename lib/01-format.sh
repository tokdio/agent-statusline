# shellcheck shell=bash
# Cheap, fork-free formatting helpers shared by every row renderer.
# All color variables are interpolated via `%b` (not embedded in the format
# string) so printf itself expands their \033 escapes without ShellCheck's
# SC2059 "don't put variables in the format string" warning applying.

sl_fmt_humanize() {
  local n=$1
  if   [ "$n" -ge 1000000 ]; then printf "%s.%sM" "$((n / 1000000))" "$(( (n / 100000) % 10 ))"
  elif [ "$n" -ge 1000 ];    then printf "%s.%sk" "$((n / 1000))"    "$(( (n / 100) % 10 ))"
  else printf "%s" "$n"
  fi
}

# Span of seconds as "2d3h" / "1h13m" / "45m"; empty if <=0
sl_fmt_span() {
  local t=${1:-0}
  [ "$t" -le 0 ] && return
  local d=$((t / 86400)) h=$((t % 86400 / 3600)) m=$((t % 3600 / 60))
  if   [ "$d" -gt 0 ]; then printf "%sd%sh" "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf "%sh%sm" "$h" "$m"
  else printf "%sm" "$m"
  fi
}

# Countdown to an epoch, relative to $SL_NOW (set once by the entrypoint).
sl_fmt_countdown() { sl_fmt_span $(( ${1:-0} - SL_NOW )); }

# OSC 8 hyperlink: clickable in iTerm2/Kitty/WezTerm, plain text elsewhere.
sl_link() {
  local esc=$'\033'
  # shellcheck disable=SC1003  # the \\ is a literal backslash terminator for the OSC 8 sequence, not an escape typo
  printf '%s]8;;%s%s\\%s%s]8;;%s\\' "$esc" "$1" "$esc" "$2" "$esc" "$esc"
}

# Print a row with a right-aligned tail: left(colored), right(colored), right(plain).
# $3 is the plain-text version of $2, needed only for width math — ANSI SGR
# and OSC 8 codes are zero visible columns but non-zero string length, so
# the padding math would be wrong if it measured the colored string.
sl_row_print() {
  local l_col=$1 r_col=$2 r_txt=$3
  if [ -z "$r_col" ]; then printf '%s\n' "$l_col"; return; fi
  local l_txt
  l_txt=$(printf '%s' "$l_col" | sed -E $'s/\x1b\\[[0-9;]*m//g; s/\x1b]8;;[^\x1b]*\x1b\\\\//g')
  local cols=${COLUMNS:-0}
  [ "$cols" -gt 0 ] 2>/dev/null || cols=$(tput cols 2>/dev/null || echo 120)
  # Claude Code indents the statusline row; reserve a margin to avoid clipping
  local pad=$(( cols - 4 - ${#l_txt} - ${#r_txt} ))
  [ "$pad" -lt 1 ] && pad=1
  printf '%s%*s%s\n' "$l_col" "$pad" "" "$r_col"
}

# cwd with $HOME collapsed to ~. `case` form, not ${var/#$HOME/~} — the
# latter is a zsh-ism that silently no-ops in bash once $HOME contains a
# literal '/' (see the statusline blog posts for the fifteen-minute story).
sl_fmt_short_cwd() {
  local cwd=$1
  case "$cwd" in
    "$HOME")   printf '~' ;;
    "$HOME"/*) printf '~%s' "${cwd#"$HOME"}" ;;
    *)         printf '%s' "$cwd" ;;
  esac
}
