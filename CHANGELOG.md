<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to zenzic-action are documented in this file. The project adheres to Semantic Versioning. Major releases represent breaking changes to inputs/outputs, minor releases introduce new options or core package bumps, and patch releases address bug fixes. Format follows Keep a Changelog.

---

## [Unreleased]

*Upcoming changes for the next release.*

### Changed

- **Core v0.31.0 changes what this action reports on an MkDocs project**: pages declared by
  `exclude_docs` or `draft_docs` are no longer analysed, because they are absent from the site the
  build produces — so a workflow that passes today may report fewer findings after the core lands.
  `draft_docs` follows `mkdocs build`, not `mkdocs serve`. A malformed pattern in `not_in_nav`,
  `exclude_docs` or `draft_docs` is now reported as `Z407` rather than silently ignored, and no
  longer aborts the run. **If your workflow compares against a committed baseline, regenerate it**:
  it lists findings the new core does not produce. The credential tier is unchanged — a secret in an
  unbuilt file still exits `2`.

### Fixed

- **The Badge Freshness Gate Depended on Third-Party Uptime, and It Is On by Default**: `check-stamp` defaults to `true`, and the `zenzic score --check-stamp` behind it validated external URLs with no way to turn that off — so a host that did not answer from the runner changed the score and failed the step on a tree nobody had touched. Measured in the core repository on CI run `35455833729`: the same commit computed **89/100** on one runner and **97** on two others, a gap of exactly one `Z104` (penalty 8.0), and a re-run of that identical commit with no change produced 97 everywhere. The wrapper now passes `--no-external` to that one invocation. **Support is asked of the binary, not derived from the `version` input** — `COLUMNS=200 zenzic score --help` is grepped for the flag — because `version` can pin any release and a semver comparison would be a second place to keep the answer; `COLUMNS` is pinned because the help wraps at a narrow width and the probe would otherwise answer "not supported" in silence, restoring the very defect. On a pinned Zenzic older than 0.31.0 the flag does not exist, the gate runs exactly as before, and the step emits a `::notice::` naming the limitation instead of hiding it. Nothing is lost: `check all` runs above it in the same job and reports a genuinely broken external link itself, with the file and the line. **If you stamp badges in CI, stamp with `zenzic score --stamp --no-external`** — stamping in one mode and verifying in the other disagrees the first time a remote host is slow. New test coverage: `tests/test_badge_check_does_not_reach_the_network.sh` exercises both branches of the probe against the real wrapper, and was confirmed to fail before the fix.

- **`nox -s tests` Listed Its Test Scripts by Hand**: the session named three `tests/test_*.sh` files literally, so a fourth added to the directory would not have run — and a test that does not run reads exactly like one that passes. The list is now a `sorted(Path("tests").glob("test_*.sh"))`, and the session errors if the glob finds nothing rather than reporting success over an empty set.

- **Stale GitHub Org Slug (`PythonWoods/zenzic-action` → `PythonWoods-Dev/zenzic-action`)**: the org was renamed at some point. `README.md`'s badges (CI-status, version-tag) and cross-repo links, `package.json`, `pyproject.toml`, `RELEASE.md`, `CONTRIBUTING.md`, `SECURITY.md`, the 3 issue templates, and `self-check.yml`'s real checkout/`ls-remote` steps against the `zenzic` Core sibling repo all still referenced the old org. Non-breaking today (GitHub 301-redirects; live-verified via `curl`/`gh api`), but non-canonical. Same defect class already fixed in `zenzic` Core's own files this session.
- **`config-file` Input Now Actually Works**: `config-file` was fully specified in `action.yml` since it was introduced, including its own path-traversal/absolute-path rejection guarantee. But the wrapper never consumed `ZENZIC_CONFIG_FILE` at all, and Zenzic core had no `--config` flag to receive it. Setting `config-file` in a workflow silently did nothing. Both sides are now real: core gained a `--config PATH` flag (see the `zenzic` core changelog). The wrapper now passes `--config "$ZENZIC_CONFIG_FILE"` to every zenzic invocation (`check all`, `score`, `score --check-stamp`, `diff`, `audit`) when the input is set, guarded by the same absolute-path/`..`-traversal rejection `action.yml` already documented (mirroring the existing `diff-base`/`sarif-file` sandbox guards). It also adds a new check that a nonexistent `config-file` fails the step rather than silently falling back to normal discovery. `action.yml`'s and `README.md`'s descriptions corrected in the same pass: the "falls back to `.github/.zenzic.toml`" claim never matched core's real discovery chain (`.zenzic.toml` → `pyproject.toml [tool.zenzic]` only) — removed. New test coverage: `tests/test_config_file_guard.sh` exercises the guard's accept and reject paths against the real wrapper script (fake `zenzic` binary on `PATH`, no network required).

- **Phantom `/docs/`-Prefixed Finding-Codes URL**: `zenzic-action-wrapper.sh`'s Exit 2 and Exit 3 step-summary tables (3 occurrences) linked to `https://zenzic.dev/docs/reference/finding-codes`, which 404s — corrected to `https://zenzic.dev/reference/finding-codes/`. Found via a global phantom-URL sweep across all four ecosystem repos; same defect class as an already-fixed `zenzic` core `README.md` issue.
- **Z202/Z203 Exit-3 Messaging Conflation**: `zenzic-action-wrapper.sh`'s Exit Code Contract header comment, `::error` annotation, and job-summary table incorrectly attributed the Exit 3 (Boundary Breach) branch to both `Z202` and `Z203`. Only `Z203` (fatal, OS-system-directory traversal) ever triggers Exit 3 — `Z202` (ordinary docs-root-boundary traversal) is deliberately non-escalated and always stays Exit 1, matching Zenzic Core's own contract. No runtime findings were ever mishandled (a `Z202` finding could never reach the Exit 3 branch); this was a misleading-message-only defect that could cause a reader of CI output to misattribute which finding code caused a build failure.
- **`tests/test_config_file_guard.sh` Was Never Invoked by Any Automated Pipeline**: the real, passing shell test suite for the `config-file` sandbox guard existed since the guard itself shipped. `noxfile.py`'s `tests` session (the only thing `just test`/CI invoke) only ran `bash -n zenzic-action-wrapper.sh` (a syntax-only check) plus the self-dogfooding gate — never this file. A regression in the guard's accept/reject logic would have gone undetected by CI despite a correct test already existing for it. Now wired in as the `tests` session's second step.

## Historical Releases

- v2.14.x archive: [changelogs/v2.14.x.md](./changelogs/v2.14.x.md)
- v2.13.x archive: [changelogs/v2.13.x.md](./changelogs/v2.13.x.md)
- v2.12.x archive: [changelogs/v2.12.x.md](./changelogs/v2.12.x.md)
- v2.11.x archive: [changelogs/v2.11.x.md](./changelogs/v2.11.x.md)
- v2.10.x archive: [changelogs/v2.10.x.md](./changelogs/v2.10.x.md)
- v2.9.x archive: [changelogs/v2.9.x.md](./changelogs/v2.9.x.md)
- v2.8.x archive: [changelogs/v2.8.x.md](./changelogs/v2.8.x.md)
- v2.7.x archive: [changelogs/v2.7.x.md](./changelogs/v2.7.x.md)
- v2.6.x archive: [changelogs/v2.6.x.md](./changelogs/v2.6.x.md)
- v2.5.x archive: [changelogs/v2.5.x.md](./changelogs/v2.5.x.md)
- v2.4.x archive: [changelogs/v2.4.x.md](./changelogs/v2.4.x.md)
- v2.3.x archive: [changelogs/v2.3.x.md](./changelogs/v2.3.x.md)
- v2.2.x archive: [changelogs/v2.2.x.md](./changelogs/v2.2.x.md)
- v2.1.x archive: [changelogs/v2.1.x.md](./changelogs/v2.1.x.md)
- v1.x archive: [changelogs/v1.x.md](./changelogs/v1.x.md)
