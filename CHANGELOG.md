<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to zenzic-action are documented in this file. The project adheres to Semantic Versioning. Major releases represent breaking changes to inputs/outputs, minor releases introduce new options or core package bumps, and patch releases address bug fixes. Format follows Keep a Changelog.

---

## [Unreleased]

*Upcoming changes for the next release.*

## [2.12.1] - 2026-08-12

Upcoming changes for the next patch release.

### Fixed

- **AST Parser (`Z511`)**: Inherited core engine fix for raw HTML block parsing to prevent false positive excessive sentence length warnings in CI workflows.
- **Sentence Length Semicolon Boundary (`Z511`)**: Inherited core engine fix recognizing semicolons as sentence boundaries to eliminate false positive warnings in CI workflows.

### Changed

- **Policy-as-Code Template Alignment**: Aligned `[policies]` configuration template documentation for `Z610` and `Z611` with Zenzic Core v0.28.1.

## [2.12.0] - 2026-08-11

Release v2.12.0 introduces compliance audit report artifact generation, enriched Enterprise SARIF v2.1.0 metadata, and Policy-as-Code Engine integration aligned with Zenzic Core v0.28.0.

### Added

- **Audit Mode Artifact Generation (`V0.28-04`)**: Added new optional input `generate_audit_report` (default: `false`). When set to `true`, the action executes `zenzic audit --format json > zenzic-audit.json` and uploads `zenzic-audit.json` as a workflow artifact (`actions/upload-artifact`).
- **Enterprise SARIF Integration (`V0.28-03`)**: Supported enriched SARIF v2.1.0 output with `helpUri`, `properties.category`, `properties.penalty`, and `fullDescription` fields mapped from Zenzic Core for GitHub Code Scanning.
- **Policy-as-Code Support (`V0.28-01`)**: Aligned action wrapper to process `Z610` (REQUIRED_FRONTMATTER_MISSING) and `Z611` (FORBIDDEN_DOMAIN_REFERENCE) governance findings.

### Fixed

- **Path Sovereignty & AST Determinism**: Inherited core engine workspace boundary enforcement (`Z202`) to prevent symlink path traversal and ensure deterministic line-offset parsing in CI workflows.

### Changed

- **Brand & Positioning Alignment (`V0.27-13`)**: Realigned Action description (`action.yml`) and README to position Zenzic as a **Deterministic Document Integrity Engine**, eradicating misleading "SAST" terminology (**Mirror Law ADR-020**).
- **Dependencies Bump**: Updated `github/codeql-action` to `v4` (`v4.37.6`) in CodeQL workflow.

---

## Historical Releases

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
