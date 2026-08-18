<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD041 -->

## Description
<!-- Describe the architectural intent of the changes and provide context. -->
Fixes #

## Type of Change

- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature breaking backward compatibility)
- [ ] Documentation update
- [ ] Refactoring / Tech Debt removal
- [ ] CI/CD workflow improvement

## Governance & Compliance Checklist

- [ ] **DCO & Signatures:** All commits are signed with DCO (`git commit -s`) and GPG/SSH (`git commit -S`).
- [ ] **Issue-First:** This PR addresses an explicitly approved Issue.
- [ ] **Changelog:** I have updated `CHANGELOG.md` under the `## [Unreleased]` section.
- [ ] **Commit Standards:** Commit messages strictly follow the Conventional Commits specification.
- [ ] **Absolute Ownership:** I have verified and can architecturally justify every single line of code. No unreviewed AI-generated code is included.

## Architectural Quality Gates (GitHub Action)

- [ ] **Version Pinning Integrity:** I have not altered the strict core version pinning without approval.
- [ ] **SARIF & Annotation Standards:** SARIF output complies strictly with Static Analysis Results Interchange Format (SARIF) v2.1.0 specification.
- [ ] **Local Quality Pipeline:** `just test` (or workflow validation suite) passes without errors.
- [ ] **Fail-Closed Security:** Security violations (exit codes 2 and 3) propagate unconditionally to the GitHub runner.
