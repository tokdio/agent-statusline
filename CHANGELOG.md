# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/); this project doesn't yet promise strict [SemVer](https://semver.org/) compatibility guarantees (it's a statusline script, not a library), but versions are tagged for anyone pinning a specific behavior.

## [1.0.2] — 2026-08-10

No behavior change from v1.0.1.

### Changed

- Both this repo and the [Homebrew tap](https://github.com/tokdio/homebrew-agent-statusline) moved from the `poudelprakash` personal account to the [`tokdio`](https://github.com/tokdio) GitHub organization. Old URLs (`github.com/poudelprakash/agent-statusline`, `github.com/poudelprakash/homebrew-agent-statusline`) 301-redirect automatically. Homebrew users: `brew untap poudelprakash/agent-statusline` and `brew install tokdio/agent-statusline/agent-statusline` — the old tap path won't receive future formula updates.
- The built script's header comment and all in-repo/tap references now point at the `tokdio` URLs.

## [1.0.1] — 2026-08-10

### Changed

- Repository renamed `claude-code-statusline` → `agent-statusline`. GitHub redirects the old URL automatically. Reasoning: the project is Claude-Code-only today, but the design is CLI-agnostic — only `lib/99-main.sh`'s `jq` field paths are Claude-Code-specific. A name change now avoids a breaking rename later if support for another agentic CLI (e.g. Codex, once [openai/codex#17827](https://github.com/openai/codex/issues/17827) ships) is added.
- README: added a Compatibility section stating current/planned CLI support explicitly.

## [1.0.0] — 2026-08-10

Initial public release.

### Added

- Three-row statusline: repo/branch state (row 1), session/model state (row 2), project state (row 3, conditional).
- Clickable OSC 8 links for the working directory, branch (→ GitHub tree view), and open PR.
- PR review-state icon + CI rollup, cached and refreshed in the background so a render never blocks on `gh`.
- Rate-limit segments with soften-near-reset coloring and a pacing arrow (▲) for usage running ahead of the window's elapsed fraction.
- Prompt-cache hit-rate percentage for the last request.
- Context budget shown as used/window with free%.
- Session duration, API busy-ratio, cost (tiered color) and burn rate ($/h).
- Row 3: GSD phase/progress, OpenSpec proposal counts (new/wip), Beads issue counts (ready/wip/blocked) — each cached where the underlying command is slow.
- Debug payload dump to `~/.cache/claude-statusline/last-input.json` on every render.
- `lib/` split into 8 namespaced, independently ShellCheck-clean modules; `build.sh` flattens them into a single fork-free generated script.
- GitHub Actions CI running ShellCheck against every module and the generated output on every push/PR.
