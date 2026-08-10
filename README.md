# claude-code-statusline

A three-row [Claude Code](https://claude.com/claude-code) statusline: repo/branch state with clickable links, open PR + CI status, session cost and duration, context budget, rate-limit pacing, prompt-cache health, and a live project-state row (GSD phase, OpenSpec proposals, [Beads](https://github.com/steveyegge/beads) issues) — built from modular, ShellCheck-clean bash.

![Statusline screenshot: repo path and branch on the left, session name, uptime, API busy-ratio and cost on the right; second row shows model, context budget, rate-limit usage, and prompt-cache hit rate](assets/statusline-example.png)

Row 3 (project state — GSD/OpenSpec/Beads) only renders when there's actually something to show; the screenshot above is a plain repo, so it's absent.

Design writeup: [Your Statusline Is the Cheapest Feedback Loop in Agentic Coding](https://www.sharmaprakash.com.np/blog/statusline-the-five-second-feedback-loop/) and the follow-up, [Statusline v2: Three Rows, Clickable Links, and a Live Project HUD](https://www.sharmaprakash.com.np/blog/statusline-v2-three-rows-live-project-hud/).

## Why

Claude Code ships the statusline slot empty and pipes a JSON payload to whatever command you configure — model, token usage, cost, context window, rate limits, PR/git state. It costs zero tokens (the model never sees it) and near-zero render time if you're careful about forks. Left blank, all of that is wasted.

## Structure

```
lib/
  00-colors.sh          base + 256-color identity palette
  01-format.sh           humanize/span/countdown/link/row_print helpers
  02-git.sh               branch + dirty/ahead-behind, one git call
  03-rate-limits.sh       pacing-aware rate-limit segments
  04-pr-ci.sh             PR review state + cached CI rollup
  05-project-state.sh     GSD / OpenSpec / Beads (row 3)
  06-model.sh             model badge with effort/fast/think qualifiers
  99-main.sh              composition root — parses the payload, renders rows
build.sh                  flattens lib/*.sh into one generated, fork-free script
```

`lib/` is the source of truth you edit. `build.sh` concatenates every module in order into a single generated file with **zero `source` calls at runtime** — sourcing doesn't fork, but it still costs a disk read per file, and this statusline re-renders on nearly every keystroke. Flattening at build time keeps editability without paying that cost on every render. Benchmarked: the generated single file performs identically (median/min render time) to a hand-written single-file version; a live `source`-per-module version measured ~5ms slower per render.

Each module is independently ShellCheck-clean. The composition root (`99-main.sh`) intentionally skips `set -euo pipefail`'s `errexit`/`nounset` — this script runs on every keystroke, and a hard failure from one flaky `git`/`jq`/`bd` call would blank the entire statusline instead of degrading gracefully. It relies on `2>/dev/null` and `${var:-0}`-style fallbacks instead.

## Install

Requires `bash`, `jq`, and `git`. `gh` (GitHub CLI) is optional, for the PR/CI row; `bd` ([Beads](https://github.com/steveyegge/beads)) is optional, for the Beads segment of row 3.

```bash
git clone https://github.com/poudelprakash/claude-code-statusline.git
cd claude-code-statusline
./build.sh
```

That writes `~/.claude/statusline-command.sh` (pass a different path as `$1` to build.sh if you want it elsewhere). Then point Claude Code at it in `~/.claude/settings.json`:

```jsonc
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh",
    "refreshInterval": 5
  }
}
```

Open a new Claude Code session in any git repo to see it render. `refreshInterval` makes rows with live state (rate-limit countdowns, CI status) re-render on a timer, not just on keystrokes.

## Making it yours

Row 3 is the part least likely to transfer as-is — `sl_proj_gsd`, `sl_proj_openspec`, and `sl_proj_beads` in `lib/05-project-state.sh` read tools specific to my workflow. The pattern is what's reusable: read a project file or run a project CLI, cache the result if it's expensive, render it only when it has something to say. Swap in your own tracker (Jira, Linear, a plain `git log --since=yesterday`) following the same shape.

After editing anything under `lib/`, re-run `./build.sh` to regenerate the deployed script.

## Debugging

Every render writes the raw JSON payload Claude Code sent to `~/.cache/claude-statusline/last-input.json`, overwritten each time. When Claude Code ships a new payload field, `cat ~/.cache/claude-statusline/last-input.json | jq` shows you what's actually there instead of guessing from docs.

## License

MIT — see [LICENSE](LICENSE).
