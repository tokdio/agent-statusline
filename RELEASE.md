# Releasing

This project is versioned with git tags (`vX.Y.Z`) and GitHub Releases, with a prebuilt `statusline-command.sh` attached to each release so it can be downloaded directly without cloning.

## Steps

1. **Update `CHANGELOG.md`.** Add a new `## [X.Y.Z] — YYYY-MM-DD` section above the previous one, following [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) (`Added` / `Changed` / `Fixed` / `Removed`).

2. **Verify before tagging** — every one of these should be clean:

   ```bash
   shellcheck lib/*.sh build.sh
   ./build.sh /tmp/statusline-command.sh
   shellcheck /tmp/statusline-command.sh
   ```

   If you're changing behavior (not just refactoring), also diff the new build's output against the currently-deployed one across a few representative JSON payloads before tagging — see the parity-check pattern used during the original refactor (empty payload, a full payload, PR/CI/worktree/max-effort, a repo with GSD/OpenSpec/Beads state).

3. **Commit and push** the changelog update (and any code changes) to `main`. Confirm the [ShellCheck workflow](.github/workflows/shellcheck.yml) is green before proceeding:

   ```bash
   gh run watch --exit-status
   ```

4. **Tag and push the tag** (must point at a commit reachable from `main` — the release workflow refuses to run otherwise):

   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z - <one-line summary>"
   git push origin vX.Y.Z
   ```

   Pushing the tag triggers the [Release workflow](.github/workflows/release.yml), which ShellChecks the source, builds `dist/statusline-command.sh`, ShellChecks the build output, pulls the matching `## [X.Y.Z]` section out of `CHANGELOG.md` for the release notes, and runs `gh release create` with the artifact attached. Watch it:

   ```bash
   gh run watch --exit-status
   ```

   If the CHANGELOG section is missing, the workflow fails before creating anything — go back to step 1.

5. **Verify the download works** before calling it done:

   ```bash
   curl -fsSL https://github.com/poudelprakash/agent-statusline/releases/latest/download/statusline-command.sh -o /tmp/verify.sh
   cmp /tmp/verify.sh dist/statusline-command.sh && shellcheck /tmp/verify.sh
   rm -f /tmp/verify.sh
   ```

6. **The Homebrew tap picks it up on its own.** [`tokdio/homebrew-tap`](https://github.com/tokdio/homebrew-tap) runs a daily `brew bump-packages` check ([`bump.yml`](https://github.com/tokdio/homebrew-tap/blob/main/.github/workflows/bump.yml)) against this repo's tags and opens a PR bumping `Formula/agent-statusline.rb`'s `url`/`sha256` when a newer tag exists. No action needed here beyond tagging — but the PR still needs a human to review/merge and trigger `publish.yml`'s bottle pull.

## Versioning

No strict SemVer contract yet (see the note in `CHANGELOG.md`) — this is a statusline script, not a library with a stable API. As a rough guide:

- **Patch** (`x.y.Z`) — bug fixes, ShellCheck/lint cleanup, no behavior change to rendered output.
- **Minor** (`x.Y.0`) — new fields/rows, new optional dependencies (e.g. a new row-3 integration), backward compatible.
- **Major** (`X.0.0`) — layout changes that alter existing output (row count, field order), or a change to `build.sh`'s CLI contract.
