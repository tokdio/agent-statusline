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

4. **Tag and push the tag:**

   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z - <one-line summary>"
   git push origin vX.Y.Z
   ```

5. **Build the release artifact** from the tagged commit and attach it:

   ```bash
   ./build.sh dist/statusline-command.sh
   shellcheck dist/statusline-command.sh
   gh release create vX.Y.Z \
     --title "vX.Y.Z — <one-line summary>" \
     --notes "$(sed -n '/## \[X.Y.Z\]/,/## \[/p' CHANGELOG.md | sed '$d')" \
     --latest
   gh release upload vX.Y.Z dist/statusline-command.sh
   ```

   (`dist/` is gitignored — it's a release artifact, not a tracked file. The `sed` pulls just the new section out of `CHANGELOG.md` for the release notes; adjust the range by hand if it grabs too much or too little.)

6. **Verify the download works** before calling it done:

   ```bash
   curl -fsSL https://github.com/poudelprakash/claude-code-statusline/releases/latest/download/statusline-command.sh -o /tmp/verify.sh
   cmp /tmp/verify.sh dist/statusline-command.sh && shellcheck /tmp/verify.sh
   rm -f /tmp/verify.sh
   ```

## Versioning

No strict SemVer contract yet (see the note in `CHANGELOG.md`) — this is a statusline script, not a library with a stable API. As a rough guide:

- **Patch** (`x.y.Z`) — bug fixes, ShellCheck/lint cleanup, no behavior change to rendered output.
- **Minor** (`x.Y.0`) — new fields/rows, new optional dependencies (e.g. a new row-3 integration), backward compatible.
- **Major** (`X.0.0`) — layout changes that alter existing output (row count, field order), or a change to `build.sh`'s CLI contract.
