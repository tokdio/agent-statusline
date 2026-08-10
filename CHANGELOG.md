# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/); this project doesn't yet promise strict [SemVer](https://semver.org/) compatibility guarantees (it's a statusline script, not a library), but versions are tagged for anyone pinning a specific behavior.

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
