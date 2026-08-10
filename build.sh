#!/bin/bash
# Flattens lib/*.sh into ~/.claude/statusline-command.sh — a single file
# with zero `source` calls, so Claude Code executes it at the same cost as
# one hand-written file. Edit a module under lib/, then run this.
set -euo pipefail

LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/lib" && pwd)"
OUT="${1:-$HOME/.claude/statusline-command.sh}"

{
  echo '#!/bin/bash'
  echo '# GENERATED FILE — do not edit directly, your changes will be overwritten.'
  echo '# Source: https://github.com/poudelprakash/claude-code-statusline'
  echo "# Edit a module under lib/, then run build.sh to regenerate this file."
  echo '#'
  echo '# Reads a JSON payload on stdin, renders three rows to stdout, exits 0 —'
  echo '# the entire Claude Code statusline contract.'
  echo
  for f in "$LIB_DIR"/*.sh; do
    echo "# ════════ $(basename "$f") ════════"
    cat "$f"
    echo
  done
} > "$OUT"

chmod +x "$OUT"
echo "built $OUT ($(wc -l < "$OUT" | tr -d ' ') lines from $(ls "$LIB_DIR"/*.sh | wc -l | tr -d ' ') modules)"
