<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD033 MD041 MD060 -->

<p align="center">
  <a href="https://github.com/PythonWoods/zenzic-action">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="assets/zenzic-wordmark-action-dark.svg">
      <img alt="Zenzic / action" src="assets/zenzic-wordmark-action.svg" width="350">
    </picture>
  </a>
</p>

<p align="center">Deterministic Document Integrity Engine and SAST for Markdown/MDX graphs.</p>

<p align="center">
  <a href="https://github.com/PythonWoods/zenzic-action/actions/workflows/self-check.yml"><img alt="ci-status" src="https://img.shields.io/github/actions/workflow/status/PythonWoods/zenzic-action/self-check.yml?branch=main&label=ci&style=flat-square"></a>
  <!-- zenzic:audit-badge -->
  <img src="https://img.shields.io/badge/%F0%9F%9B%A1%EF%B8%8F_zenzic--audit-passing-22c55e?style=flat-square" alt="zenzic-audit">
  <!-- zenzic:score-badge -->
  <img src="https://img.shields.io/badge/%F0%9F%9B%A1%EF%B8%8F_zenzic--score-100_%2F_100-4f46e5?style=flat-square" alt="zenzic-score">
  <a href="https://github.com/PythonWoods/zenzic-action/releases"><img alt="action version" src="https://img.shields.io/github/v/tag/PythonWoods/zenzic-action?sort=semver&label=action&color=4f46e5&style=flat-square"></a>
  <a href="https://pypi.org/project/zenzic"><img alt="zenzic on PyPI" src="https://img.shields.io/pypi/v/zenzic?label=zenzic&color=0284c7&style=flat-square"></a>
  <a href="https://pepy.tech/project/zenzic"><img alt="Downloads" src="https://img.shields.io/pepy/dt/zenzic?color=4f46e5&label=downloads&style=flat-square"></a>
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/badge/license-Apache--2.0-0d9488?style=flat-square"></a>
  <a href="https://reuse.software/"><img alt="REUSE 3.x compliant" src="https://img.shields.io/badge/REUSE-3.x%20compliant-0d9488?style=flat-square"></a>
</p>

---

Run Zenzic SAST and graph integrity analysis in CI — surfacing results directly in GitHub Code Scanning without reading logs.

**Exit code contract (ADR-075).** The wrapper propagates Zenzic's exit codes without remapping. Exit 1 (quality) obeys `fail-on-error`. Exit 2 (credential) and exit 3 (path traversal) terminate the job regardless of `fail-on-error: false` or `--exit-zero` — security findings are never suppressed at the enforcement boundary.

---

## Core Features

| Feature | Category | Description |
|---|---|---|
| **Security Scanning (SAST)** | Security | Detects hardcoded tokens (Z201) and path traversal (Z202/Z203); exits 2/3 survive `fail-on-error: false` |
| **Graph Topology Analysis** | Topology | Virtual Site Map (VSM) verifies cross-file links, orphan pages, and dead navigation graph nodes |
| **Deterministic CI/CD Enforcement** | CI/CD | Zero-DBT quality gate ensuring bit-for-bit reproducible enforcement across build environments |
| **Zero-setup install** | Execution | `uvx zenzic` — no Python toolchain required on the runner |
| **SARIF output** | Integration | Findings feed directly into GitHub Code Scanning |
| **Sovereign Audit mode** | Security | `audit: "true"` bypasses suppressions to reveal unfiltered documentation graph state |
| **PR annotations** | Feedback | Inline findings on diffs, colour-coded by severity |
| **Version pinning** | Governance | Pin to exact release (e.g. `0.25.0`) for deterministic, reproducible CI gates |

---

## Quick Start

The minimal configuration — zero Python setup, SARIF to Code Scanning in one step:

```yaml
- uses: actions/checkout@v4

- name: Run Zenzic Documentation Quality Gate
  uses: PythonWoods/zenzic-action@v2
  with:
    version: "0.25.0"
    format: sarif
    upload-sarif: "true"
  permissions:
    contents: read
    security-events: write
```

Place a `.zenzic.toml` at the root of your repository and the action picks it up automatically — no `config-file` input required. Run `zenzic init` once to scaffold a config if your docs live outside the default `docs/` folder.

For advanced configuration (Configuration Discovery, Sovereign Override, Quality Gate scoring, nightly audit), see the [Zenzic Action docs](https://zenzic.dev/docs/reference/zenzic-action).


---

## 🔍 Visual Feedback

Zenzic Action surfaces findings directly where you work — no digging through CI logs.

<p align="center">
  <img alt="GitHub Code Scanning showing Zenzic findings" src="assets/sarif-showcase.svg?v=2" width="800">
</p>

---

## Integration Blueprints

### 1. Baseline Check (SAST & Topology Verification)
This blueprint provides static application security testing (SAST), link validation, and graph topology verification. It executes during pushes and PRs, ensuring no broken links, credential leaks, or invalid configurations enter the repository.

```yaml
name: Zenzic Baseline Audit

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  baseline-check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Run Zenzic Baseline
        uses: PythonWoods/zenzic-action@v2
        with:
          version: "0.25.0"
          format: text
          fail-on-error: "true"
```

### 2. Security Hardening (SARIF + Upload Integration)
This blueprint runs a security-hardened gate. It executes the secret scanner (`guard-scan`) to catch exposed credentials and path traversals, then uploads the SARIF report directly to the GitHub Code Scanning Security tab.

```yaml
name: Zenzic Hardened Quality Gate

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  security-gate:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Run Hardened Zenzic Audit
        uses: PythonWoods/zenzic-action@v2
        with:
          version: "0.25.0"
          format: sarif
          upload-sarif: "true"
          guard-scan: "true"
```

### 3. PR Governance (Inline Annotations & DQS Tracking)
This blueprint implements pull-request governance. It downloads the DQS baseline from the default branch, runs the quality gate comparison, maps issues to inline annotations, and publishes a summary of the Document Quality Score (DQS) to the workflow run.

```yaml
name: Zenzic PR Governance & DQS Tracking

on:
  pull_request:
    branches: [ main ]

jobs:
  pr-governance:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Run PR Governance Check
        uses: PythonWoods/zenzic-action@v2
        with:
          version: "0.25.0"
          format: text
          fail-on-error: "true"
```

### 4. Sovereign Nightly Audit (Full Unfiltered Audit)
Runs an unsuppressed audit on schedule, reporting hidden technical debt directly to Code Scanning.

```yaml
name: Zenzic Sovereign Audit

on:
  schedule:
    - cron: "0 2 * * *"  # Daily at 02:00 UTC

jobs:
  sovereign-audit:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Run Sovereign Audit
        uses: PythonWoods/zenzic-action@v2
        with:
          version: "0.25.0"
          audit: "true"
          format: sarif
          upload-sarif: "true"
```

---

## Action Inputs Reference

| Input | Default | Description |
|:---|:---|:---|
| `version` | `"latest"` | Zenzic Core version to execute (e.g., `"0.25.0"`) |
| `format` | `"text"` | Output format: `text`, `json`, or `sarif` |
| `upload-sarif` | `"false"` | Automatically upload SARIF output to GitHub Code Scanning |
| `guard-scan` | `"false"` | Triggers fatal pre-gate security scan (`zenzic guard scan`) |
| `audit` | `"false"` | Sovereign Audit mode: bypasses all active suppressions |
| `fail-on-error` | `"true"` | Controls job failure for quality findings (Exit 1) |
| `config-file` | `""` | Optional path to custom `.zenzic.toml` configuration |

---

## Responsibility Matrix (ADR-075)

| Concern | Zenzic Core | Zenzic Action |
|:---|:---:|:---:|
| Link & Topology validation | ✅ | Executes Core |
| Credential scanner (Z2xx) | ✅ | Executes Core |
| Exit-code contract (0/1/2/3) | ✅ | Enforced |
| GitHub Annotations (`::error::`) | — | ✅ |
| Code Scanning SARIF upload | — | ✅ |
| PR inline diff annotations | — | ✅ |

---

## License & Support

Licensed under Apache-2.0. For complete finding taxonomy and developer guides, visit [zenzic.dev](https://zenzic.dev).
