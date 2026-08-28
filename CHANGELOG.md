<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to zenzic-action are documented in this file. The project adheres to Semantic Versioning. Major releases represent breaking changes to inputs/outputs, minor releases introduce new options or core package bumps, and patch releases address bug fixes. Format follows Keep a Changelog.

---

## [Unreleased]

### Fixed

- **Phantom `/docs/`-Prefixed Finding-Codes URL**: `zenzic-action-wrapper.sh`'s Exit 2 and Exit 3 step-summary tables (3 occurrences) linked to `https://zenzic.dev/docs/reference/finding-codes`, which 404s — corrected to `https://zenzic.dev/reference/finding-codes/`. Found via a global phantom-URL sweep across all four ecosystem repos; same defect class as an already-fixed `zenzic` core `README.md` issue.
- **Z202/Z203 Exit-3 Messaging Conflation**: `zenzic-action-wrapper.sh`'s Exit Code Contract header comment, `::error` annotation, and job-summary table incorrectly attributed the Exit 3 (Boundary Breach) branch to both `Z202` and `Z203`. Only `Z203` (fatal, OS-system-directory traversal) ever triggers Exit 3 — `Z202` (ordinary docs-root-boundary traversal) is deliberately non-escalated and always stays Exit 1, matching Zenzic Core's own contract. No runtime findings were ever mishandled (a `Z202` finding could never reach the Exit 3 branch); this was a misleading-message-only defect that could cause a reader of CI output to misattribute which finding code caused a build failure.

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
