#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0
#
# test_sarif_file_guard.sh — real-execution coverage for the SARIF path sandbox
# guard in zenzic-action-wrapper.sh (BUG-006, "Action SARIF Jailbreak").
#
# sarif-file is a WRITE path, which makes this the highest-blast-radius of the
# three path guards: an unguarded absolute or traversal value lets a workflow
# write attacker-chosen content outside the checkout — into another step's
# workspace, or over a file on the runner. The two rejection branches are
# shared with the other path guards and live in lib/guard_harness.sh.
#
# Two things distinguish this guard from diff-base and config-file:
#   1. It runs unconditionally. There is no `if [ -n ... ]` wrapper, because
#      sarif-file always has a value (action.yml gives it a default).
#   2. It never checks existence — the file is an output, so "not found" is
#      the normal case and must not warn or fail.
#
# Usage: bash tests/test_sarif_file_guard.sh
# Exits 0 if every case passes, 1 on the first failure.

set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/guard_harness.sh"

echo "=== sarif-file guard: shared rejection branches ==="
assert_rejects_absolute_and_traversal \
  "ZENZIC_SARIF_FILE" "SARIF Jailbreak" "sarif-file"

echo "=== sarif-file guard: the write-escape shapes specifically ==="
assert_rejected "sarif-file: '/tmp/pwned.sarif' (absolute write escape) rejected" \
  "SARIF Jailbreak" "ZENZIC_SARIF_FILE=/tmp/pwned.sarif"
assert_rejected "sarif-file: 'out/../../../pwned.sarif' (nested traversal) rejected" \
  "SARIF Jailbreak" "ZENZIC_SARIF_FILE=out/../../../pwned.sarif"
assert_rejected "sarif-file: bare '..' rejected" \
  "SARIF Jailbreak" "ZENZIC_SARIF_FILE=.."
assert_rejected "sarif-file: trailing 'out/..' rejected" \
  "SARIF Jailbreak" "ZENZIC_SARIF_FILE=out/.."

echo "=== sarif-file guard: valid relative path accepted, threaded and reported ==="
result="$(run_wrapper "ZENZIC_SARIF_FILE=reports/results.sarif" "HARNESS_PRECREATE_DIR=reports")"
exit_code="$(_field "${result}" 1)"
invoke_log="$(_field "${result}" 2)"
stderr_log="$(_field "${result}" 3)"
if [ "${exit_code}" -eq 0 ] && [ -s "${invoke_log}" ]; then
  pass "valid nested relative path accepted (exit 0, analyzer invoked)"
else
  fail "valid relative sarif-file should be accepted (exit=${exit_code})"
  cat "${stderr_log}"
fi

echo "=== sarif-file guard: nonexistent output path is normal, must not warn ==="
# Distinguishes this guard from config-file/diff-base, which do check existence.
if [ "${exit_code}" -eq 0 ] && ! grep -qi "not found" "${stderr_log}"; then
  pass "output path that does not yet exist produces no not-found diagnostic"
else
  fail "sarif-file must not existence-check its own output path"
  cat "${stderr_log}"
fi

echo "=== sarif-file guard: '..' inside a filename is not a traversal ==="
# Pins the guard's real precision. The pattern is `*../*|*/..|..`, so a bare
# `..` only matches as a whole path segment — `v1..2` is a legitimate directory
# name and must be accepted. Asserted in one direction deliberately: a test
# that passed either way would prove nothing about the guard.
result="$(run_wrapper "ZENZIC_SARIF_FILE=reports/v1..2/results.sarif" "HARNESS_PRECREATE_DIR=reports/v1..2")"
exit_code="$(_field "${result}" 1)"
stderr_log="$(_field "${result}" 3)"
if [ "${exit_code}" -eq 0 ] && ! grep -q "SARIF Jailbreak" "${stderr_log}"; then
  pass "'reports/v1..2/results.sarif' accepted — no false positive on a dotted filename"
else
  fail "guard over-rejects: 'v1..2' is a filename, not a traversal (exit=${exit_code})"
  cat "${stderr_log}"
fi

echo "=== sarif-file: a nested output path is created, not assumed to exist ==="
# The wrapper redirects analyzer stdout into ${ZENZIC_SARIF_FILE}. A redirect
# does not create intermediate directories, so `sarif-file: reports/out.sarif`
# on a workspace with no reports/ directory failed at the shell level -- and the
# failure surfaced as the SARIF-integrity warning ("process was likely aborted
# ... SIGKILL or runtime crash"), blaming the analyzer for a missing directory.
# NOTE: deliberately no HARNESS_PRECREATE_DIR here -- that is the whole point.
result="$(run_wrapper "ZENZIC_SARIF_FILE=reports/nested/out.sarif")"
exit_code="$(_field "${result}" 1)"
stderr_log="$(_field "${result}" 3)"
workdir="$(_field "${result}" 4)"
if [ "${exit_code}" -eq 0 ] \
   && [ -f "${workdir}/reports/nested/out.sarif" ] \
   && ! grep -q "SARIF truncated" "${stderr_log}"; then
  pass "nested output directory created; SARIF written, no truncation warning"
else
  fail "wrapper must create sarif-file's parent directory (exit=${exit_code})"
  cat "${stderr_log}"
fi

report_and_exit
