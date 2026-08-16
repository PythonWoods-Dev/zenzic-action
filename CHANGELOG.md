<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to zenzic-action are documented in this file. The project adheres to Semantic Versioning. Major releases represent breaking changes to inputs/outputs, minor releases introduce new options or core package bumps, and patch releases address bug fixes. Format follows Keep a Changelog.

---

## [Unreleased]

*Upcoming changes for the next release.*

## [2.14.0] - 2026-08-15

Release notes for the `v2.14.0` release of `zenzic-action`.

### Changed

- **Single Tool Provisioning (`uv tool install`)**: Replaced ephemeral multi-invocation `uvx` executions with a single, isolated tool installation (`uv tool install --isolated --force "zenzic==${ZENZIC_VERSION}"`), caching the binary across all step executions (`check`, `score`, `diff`, `audit`) and eliminating redundant network downloads.
- **Core Baseline Alignment (`v0.30.0`)**: Bumped default pinned Zenzic Core engine to `v0.30.0`, adding CI/CD quality gate enforcement and SARIF code scanning annotations for AST semantic linting (`Z513`–`Z520`) and Policy-as-Code rules (`Z617`–`Z619`).

### Security

- **Shell Injection Defense**: Hardened `zenzic-action-wrapper.sh` by adding strict `--` parameter delimiters to all commands handling user-provided path and version inputs (`cd --`, `realpath -m --`).
- **SemVer Input Validation**: Added strict SemVer regex validation (`^[0-9]+\.[0-9]+\.[0-9]+([a-zA-Z0-9.-]+)?$`) to reject malformed or potentially malicious version strings before execution.
- **Resilient SARIF Uploads**: Configured `continue-on-error: true` on SARIF upload steps so pull requests from fork repositories lacking `security-events: write` permissions do not fail the workflow gate.

## [2.13.1] - 2026-08-14

Release notes for the `v2.13.1` release of `zenzic-action`.

### Changed

- **Core Baseline Alignment**: Realigned default pinned Zenzic Core dependency to `v0.29.1`, inheriting core engine fixes for `Z401` (Missing Directory Index) false positives on dynamic directories.


## [2.13.0] - 2026-08-13

Release notes for the `v2.13.0` release of `zenzic-action`.

### Added

- **Policy-as-Code Engine Alignment (`v0.29.0`)**: Aligned the GitHub Action with Zenzic Core `v0.29.0`, enabling CI/CD enforcement and automated PR checks for the new Policy-as-Code governance rules (`Z612`–`Z616`).

---

## Historical Releases

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
