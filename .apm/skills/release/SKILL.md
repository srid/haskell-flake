---
name: release
description: Cut a new haskell-flake release — CHANGELOG, PR, tag, GitHub release.
argument-hint: "<version>"
---

# Release

Cut `haskell-flake` release `X.Y.Z`. Pure Nix flake — no cabal/Hackage step; CHANGELOG is the only artifact, the git tag *is* the release.

Idempotent: invoke once to prep the PR, human merges, invoke again to publish.

## Conventions

- Tag / release title: `X.Y.Z` (no `v` prefix).
- CHANGELOG heading: `## X.Y.Z (MMM D, YYYY)` — e.g. `## 1.0.0 (Apr 16, 2026)`.
- Branch: `release-X.Y.Z`. Commit: `chore: Tag release X.Y.Z`. PR title: `Release X.Y.Z`.

## Flow

Detect state in order, run the matching phase:

1. `git ls-remote --tags origin refs/tags/X.Y.Z` non-empty → already published, exit.
2. `gh pr list --state merged --search "Release X.Y.Z in:title"` non-empty → **publish**.
3. `gh pr list --state open --search "Release X.Y.Z in:title"` non-empty → report status, tell user to merge then re-invoke.
4. Otherwise → **prep**.

### Prep

Require: clean tree, on `master` up-to-date with `origin/master`, `CHANGELOG.md:3` equals `## Unreleased`, tag `X.Y.Z` doesn't exist.

```sh
git checkout -b release-X.Y.Z
# Edit CHANGELOG.md: `## Unreleased` → `## X.Y.Z (<today>)`
git commit -am "chore: Tag release X.Y.Z"
git push -u origin release-X.Y.Z
gh pr create --draft --title "Release X.Y.Z" --body "Re-invoke \`/release X.Y.Z\` after merge to tag + publish."
```

Return PR URL. Stop.

### Publish

```sh
git checkout master && git pull --ff-only
NOTES=$(mktemp)
awk -v v=X.Y.Z '$0 ~ "^## "v" " {f=1; next} /^## / {f=0} f' CHANGELOG.md \
  | awk 'NF{p=1} p' | tac | awk 'NF{p=1} p' | tac > "$NOTES"
gh release create X.Y.Z --target master --title X.Y.Z --notes-file "$NOTES"
rm -f "$NOTES"
```

`gh release create` creates the tag itself — no separate `git tag`. The double `tac|awk` trims leading then trailing blank lines from the extracted section.

Report release URL.

## Out of scope

No next-cycle `## Unreleased` insertion. No version bumps (no such files). No Hackage. Does not pick the version or merge the PR.
