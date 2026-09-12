<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Release Procedure — zenzic-action

## Release Metadata

| Field   | Value      |
| :------ | :--------- |
| Version | v2.14.0    |
| Date    | 2026-08-15 |
| Status  | Stable     |

## Release Checklist

Before tagging, every item must be green:

- [ ] `action.yml` — `default:` pin updated to the latest Zenzic core version (`0.30.0`)
- [ ] `package.json` version bumped to `2.14.0`
- [ ] `pyproject.toml` — synchronized with core pin (`zenzic==0.30.0`)
- [ ] `just versions` — returns `✅ Ecosystem alignment verified.`
- [ ] `just verify` — exits 0
- [ ] `zenzic check .` — zero findings (DQS 100/100)

## Bump & Publish

```bash
# 1. Create release branch
git checkout -b release/vX.Y.Z

# 2. Preview orchestrated release (version bump + core pin)
just release-dry <patch|minor|major> <core-version>

# 3. Execute orchestrated release in one signed commit
just release <patch|minor|major> <core-version>

# 4. Validate release metadata/core-pin parity
just audit-release

# 5. Open and merge PR into main. SQUASH — see below.

# 6. Switch to main and pull latest
git checkout main
git pull origin main

# 7. Create the release tag and push
just release-tag            # always -s, and verifies its own output
git push origin v2.14.0

# 8. Move the floating v2 tag to the new release:
git tag -s -fa v2 v2.14.0^{} -m "release: v2.14.0"
git push origin v2 --force

# Verification (Atomic Parity Check):
git rev-parse v2^{} v2.14.0^{}
# SUCCESS: Both hashes must be identical.
```

Distribution target: **GitHub Actions Marketplace** — `uses: PythonWoods-Dev/zenzic-action@v2`.

## Where the pre-squash commits go

Pull requests are merged with **squash**: it is the only one of GitHub's merge
methods this repository's rules allow. A merge commit is rejected, and a rebase
merge is refused with `Base branch requires signed commits. Rebase merges
cannot be automatically signed by GitHub`.

The individual commits of a pull request remain available afterwards, including
once its branch has been deleted:

```bash
git fetch origin refs/pull/96/head:refs/heads/pr-96-history
git log pr-96-history
```

## Version Scheme

| Increment | Trigger                                      |
| :-------- | :------------------------------------------- |
| PATCH     | Wrapper script fixes, documentation, CI      |
| MINOR     | New inputs/outputs, core pin update          |
| MAJOR     | Breaking changes to inputs or output schema  |

## Changelog Reference

For a detailed list of changes, see [CHANGELOG.md](./CHANGELOG.md).
