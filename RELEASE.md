<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Release Procedure — zenzic-action

## Release Metadata

| Field   | Value      |
| :------ | :--------- |
| Version | v2.10.2 |
| Date    | 2026-07-28 |
| Status  | Stable     |

## Release Checklist

Before tagging, every item must be green:

- [ ] `action.yml` — `default:` pin updated to the latest Zenzic core version (`0.26.2`)
- [ ] `package.json` version bumped to `2.10.2`
- [ ] `pyproject.toml` — synchronized with core pin (`zenzic==0.26.2`)
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

# 5. Open and merge PR into main

# 6. Switch to main and pull latest
git checkout main
git pull origin main

# 7. Create the release tag and push
git tag -s -m "Release v2.10.2" v2.10.2
git push origin v2.10.2

# 8. Move the floating v2 tag to the new release:
git tag -s -fa v2 v2.10.2^{} -m "release: v2.10.2"
git push origin v2 --force

# Verification (Atomic Parity Check):
git rev-parse v2^{} v2.10.2^{}
# SUCCESS: Both hashes must be identical.
```

Distribution target: **GitHub Actions Marketplace** — `uses: PythonWoods/zenzic-action@v2`.

## Version Scheme

| Increment | Trigger                                      |
| :-------- | :------------------------------------------- |
| PATCH     | Wrapper script fixes, documentation, CI      |
| MINOR     | New inputs/outputs, core pin update          |
| MAJOR     | Breaking changes to inputs or output schema  |

## Changelog Reference

For a detailed list of changes, see [CHANGELOG.md](./CHANGELOG.md).
