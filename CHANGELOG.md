# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/); this project doesn't yet promise strict [SemVer](https://semver.org/) compatibility guarantees (it's a statusline script, not a library), but versions are tagged for anyone pinning a specific behavior.

## [Unreleased]

### Added

- Homebrew install path via a new tap, [`tokdio/tap`](https://github.com/tokdio/homebrew-tap) — `brew install tokdio/tap/agent-statusline`. This repo itself stays under the `poudelprakash` personal account; only the Homebrew tap lives under the [`tokdio`](https://github.com/tokdio) org, as a shared tap intended to host formulae (and future casks) for other tokdio projects too, not just this one.

> **Note:** a `v1.0.2` was briefly tagged and released to move this whole repo under the `tokdio` org, then retracted (tag and release deleted) in favor of the narrower change above — only the Homebrew tap moves, not the repo. No public install ever used that release; skipping straight to the next real version bump rather than reusing `1.0.2`.

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
