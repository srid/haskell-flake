---
name: release
description: Cut a new haskell-flake release end-to-end — CHANGELOG, PR, merge-wait, tag, GitHub release.
argument-hint: "<version>"
---

# Release

Cut a new `haskell-flake` release from start to finish. haskell-flake is a pure Nix flake — there's no cabal version to bump, no Hackage upload. The only version artifact is `CHANGELOG.md`; the git tag *is* the release.

**Single-invocation workflow.** `/release X.Y.Z` is idempotent and state-aware: invoke it at any stage and it picks up where things left off. Typical sequence:

1. First invocation → prep phase: branch, CHANGELOG edit, commit, draft PR.
2. Human reviews and merges the PR.
3. Re-invoke → publish phase: pull master, create tag + GitHub release.

Do not try to wait for the merge in-process. Exit after prep, let the human merge, then be re-invoked.

## Conventions (non-negotiable)

Grounded in prior releases 0.1.0–1.0.0:

- **Tag format**: `X.Y.Z` — no `v` prefix.
- **CHANGELOG heading**: `## X.Y.Z (MMM D, YYYY)` — abbreviated month, no leading zero on day. Example: `## 1.0.0 (Apr 16, 2026)`.
- **Branch name**: `release-X.Y.Z`
- **Commit message**: `chore: Tag release X.Y.Z`
- **PR title**: `Release X.Y.Z`
- **GitHub release title**: `X.Y.Z` (same as tag)
- **GitHub release notes**: CHANGELOG section body without the heading line.

## Arguments

`<version>`: required, e.g. `1.0.0`. Reject anything starting with `v` or not matching `^\d+\.\d+\.\d+$`.

## State detection (run first)

Before doing anything, determine the phase by checking in order:

1. **Already published** — `git ls-remote --tags origin refs/tags/X.Y.Z` returns a ref: release is done. Report and exit.
2. **Merged, not yet tagged** — `gh pr list --state merged --search "Release X.Y.Z in:title" --json number,mergeCommit` returns a PR: go to **publish phase**.
3. **PR open** — `gh pr list --state open --search "Release X.Y.Z in:title"` returns a PR: report its status (CI, review, mergeable) and exit with instructions to merge then re-invoke.
4. **Nothing started** — go to **prep phase**.

The search is title-scoped (`in:title`) to avoid matching PRs that merely mention the version in their body.

## Prep phase

Preconditions (hard-fail if violated):

1. Working tree clean: `git status --porcelain` empty.
2. On `master` and up-to-date: `git fetch origin && git rev-parse HEAD` equals `git rev-parse origin/master`.
3. `CHANGELOG.md` line 3 is exactly `## Unreleased`. If not, stop — either a release is partially in progress, or the CHANGELOG wasn't maintained.
4. Tag `X.Y.Z` does not exist locally or on remote.

Steps:

1. `git checkout -b release-X.Y.Z`
2. Edit `CHANGELOG.md`: replace `## Unreleased` with `## X.Y.Z (<today>)` using `MMM D, YYYY` format (today's date from context). Do not touch the body — the Unreleased bullets are the release notes.
3. `git add CHANGELOG.md && git commit -m "chore: Tag release X.Y.Z"`
4. `git push -u origin release-X.Y.Z`
5. Open draft PR:

   ```sh
   gh pr create --draft --title "Release X.Y.Z" --body "$(cat <<'EOF'
   ## Summary

   Tag release X.Y.Z. Renames `## Unreleased` → `## X.Y.Z (<date>)` in `CHANGELOG.md`.

   ## After merge

   Re-invoke `/release X.Y.Z` to create the tag and GitHub release from the CHANGELOG section.

   ## Test plan

   - [ ] `nix flake check` passes
   - [ ] CI green
   EOF
   )"
   ```

Return the PR URL. Tell the user to review, mark ready, and merge — then re-invoke `/release X.Y.Z` to publish.

## Publish phase

Preconditions:

1. PR `Release X.Y.Z` is merged (already confirmed by state detection).
2. Tag `X.Y.Z` does not exist yet.

Steps:

1. Sync local master to the merge commit:

   ```sh
   git checkout master && git pull --ff-only origin master
   ```

2. Sanity check: `CHANGELOG.md` on master now has `## X.Y.Z (<date>)` at line 3.

3. Extract release notes — the CHANGELOG section body without the heading, trimmed of leading/trailing blank lines, into a tmp file:

   ```sh
   NOTES=$(mktemp)
   awk -v ver="X.Y.Z" '
     $0 ~ "^## " ver " " {flag=1; next}
     /^## / {flag=0}
     flag
   ' CHANGELOG.md | awk 'NF {p=1} p' | tac | awk 'NF {p=1} p' | tac > "$NOTES"
   ```

   The double `tac | awk` trick strips leading blanks and then (reversed) trailing blanks. Inspect `$NOTES` — should be the bullet list, no `## ` heading.

4. Create tag + GitHub release in one shot. `gh release create` creates the tag itself when none exists; no separate `git tag`/`git push --tags` needed:

   ```sh
   gh release create X.Y.Z \
     --target master \
     --title X.Y.Z \
     --notes-file "$NOTES"
   ```

   Use `--notes-file` (not `--notes`) so the body round-trips through shell safely regardless of content.

5. Verify: `gh release view X.Y.Z` shows the release; `git fetch --tags && git tag -l X.Y.Z` confirms the tag locally.

6. `rm -f "$NOTES"`.

Report the release URL.

## What this skill does NOT do

- Does **not** open a `## Unreleased` section for the next cycle. Add one when the next changelog-worthy change lands.
- Does **not** bump any version in source files (there are none — no cabal, no `version.nix`).
- Does **not** publish to Hackage or any package registry.
- Does **not** decide the version number. The caller picks; sanity-check it's a plausible bump from the current latest tag (`gh release view --json tagName`) but do not override the caller's choice.
- Does **not** merge the PR. Human approves and merges.
