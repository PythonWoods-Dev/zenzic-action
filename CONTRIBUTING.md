<!--
SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
SPDX-License-Identifier: Apache-2.0
-->

# Contributing to zenzic-action

Thank you for contributing to the official GitHub Action for Zenzic!

`zenzic-action` wraps the Zenzic Core binary for seamless execution within GitHub Actions workflows, converting findings into native GitHub Annotations and uploading SARIF reports to Code Scanning.

---

## Multi-Repo Ecosystem Architecture

Zenzic is structured across three independent, dedicated repositories:

| Repository | Purpose | Primary Stack |
|:---|:---|:---|
| **[zenzic](https://github.com/PythonWoods/zenzic)** | Python Core analysis engine & CLI (`src/zenzic`) | Python 3.10+, `uv`, `pytest`, `mypy` |
| **[zenzic-vscode](https://github.com/PythonWoods/zenzic-vscode)** | Official VS Code Extension (LSP Thin Client) | TypeScript, Node.js 24+, VS Code API |
| **[zenzic-action](https://github.com/PythonWoods/zenzic-action)** (this repo) | Official GitHub Action CI/CD Wrapper | YAML, Bash, SARIF Upload |

---

## Core Dependency & Sovereign Local-Core Model

Runtime distribution for downstream users remains pinned to published Zenzic Core releases (currently pinned to **Zenzic Core `v0.25.0`**).

Repository quality gates (self-check, just, nox), however, use the shared sovereign local-core model.

Branch parity resolution in CI follows this precedence:

1. Explicit override via repository variable `ZENZIC_CORE_REF`.
2. Same-name branch parity (`github.base_ref` or `github.ref_name`).
3. Fallback to `main` if the target branch does not exist in core.

Override governance is mandatory (fail-closed): when `ZENZIC_CORE_REF` is set, the following repository variables are required:

1. `ZENZIC_CORE_REF_TICKET` (change/audit ticket)
2. `ZENZIC_CORE_REF_REASON` (explicit justification)
3. `ZENZIC_CORE_REF_APPROVER` (owner who approved)
4. `ZENZIC_CORE_REF_EXPIRES_ON` (UTC date in `YYYY-MM-DD`)

If metadata is missing, malformed, expired, or the branch does not exist in core, CI stops with an explicit error.

---

## Enterprise Governance & Contribution Policy

To maintain security, architectural integrity, and legal compliance, all contributions must adhere to these guidelines:

1. **Issue-First Policy**: No Pull Request will be reviewed or merged unless it is preceded by an Issue formally discussed and approved by maintainers. Link the approved Issue in your PR description.
2. **Mandatory Cryptographic Commit Signatures**: Every commit must be cryptographically signed using GPG, SSH, or S/MIME keypairs (appearing as **Verified** on GitHub). Unsigned commits will be rejected by branch rulesets.
3. **No AI Slop Clause**: We enforce a strict policy against unverified AI-generated code. Contributors must fully understand, explain, and architecturally justify every single line of code proposed in a PR.
4. **Developer Certificate of Origin (DCO)**: All commits must include a `Signed-off-by:` line (using `git commit -s`) certifying compliance with the DCO.
5. **Conventional Commits**: Commit messages must strictly follow the Conventional Commits specification (e.g., `feat(action): add SARIF upload retry logic (#89)`).

---

## First-Time Setup

Install pre-commit hooks (run once after cloning):

```bash
uvx pre-commit install               # commit-stage: hygiene + zenzic self-check
uvx pre-commit install -t pre-push   # pre-push: 🛡️ Final Guard runs `just verify`
```

Configure SSH commit signing (required — all commits must appear **Verified** on GitHub):

```bash
# One-time global setup (skip if already configured)
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub   # adjust path if different
git config --global commit.gpgsign true
```

Register your public key as a **Signing Key** at <https://github.com/settings/ssh>.

---

## Local Verification

Use `just` to run self-tests before opening a PR:

```bash
just lint      # fast pass: pre-commit hooks only
just verify    # full gate: pre-commit + Zenzic check + integration tests
```

Both must pass with zero errors before opening or updating a PR.

---

## Maintainer Only: Workflow Hardening & Release Procedure

### Immutable Pre-Commit Hooks (ADR-089)

All `rev:` keys in `.pre-commit-config.yaml` must point to an **immutable commit hash pin**, never to a semantic tag (`v1.2.3`).

Updating pinned hooks:
```bash
uvx pre-commit autoupdate --freeze
```

### Release Procedure

```bash
# 1. Ensure branch is clean and checks are green
just verify

# 2. Update the Zenzic core pin to the target version (e.g., 0.25.0)
just pin-core 0.25.3

# 3. Check alignment between core and action dependencies
just versions

# 4. Preview version changes (dry-run)
just release-dry patch

# 5. Apply the version bump, commit, and create tag
just release patch

# 6. Push commit and tag
git push && git push --tags
```
