#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0
#
# test_diff_base_guard.sh — real-execution coverage for the diff-base sandbox
# guard in zenzic-action-wrapper.sh.
#
# diff-base is a READ path (a JSON score snapshot), which makes its guard the
# one protecting against exfiltration rather than arbitrary write: without it a
# workflow could point diff-base at any file the runner can read. The two
# rejection branches are shared with the other path guards and live in
# lib/guard_harness.sh.
#
# The behaviour unique to this guard, and the reason it needs its own file: a
# *nonexistent* relative path is NOT an error here. It emits a warning and
# falls back to the saved .zenzic-score.json snapshot, exiting 0. That is the
# opposite of config-file, where a missing file is a hard exit 1 — so a test
# copied from that guard would assert exactly the wrong thing.
#
# Usage: bash tests/test_diff_base_guard.sh
# Exits 0 if every case passes, 1 on the first failure.

set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/guard_harness.sh"

echo "=== diff-base guard: shared rejection branches ==="
assert_rejects_absolute_and_traversal \
  "ZENZIC_DIFF_BASE" "diff-base Jailbreak" "diff-base"

echo "=== diff-base guard: trailing '..' and bare '..' rejected ==="
assert_rejected "diff-base: bare '..' rejected" "diff-base Jailbreak" "ZENZIC_DIFF_BASE=.."
assert_rejected "diff-base: trailing 'scores/..' rejected" "diff-base Jailbreak" "ZENZIC_DIFF_BASE=scores/.."

echo "=== diff-base guard: missing file warns and falls back (NOT an error) ==="
result="$(run_wrapper "ZENZIC_DIFF_BASE=scores/absent.json")"
exit_code="$(_field "${result}" 1)"
invoke_log="$(_field "${result}" 2)"
stderr_log="$(_field "${result}" 3)"
if [ "${exit_code}" -eq 0 ] \
   && grep -q "diff-base Not Found" "${stderr_log}" \
   && ! grep -q -- "--base" "${invoke_log}"; then
  pass "missing diff-base warns, exits 0, and passes no --base (falls back to snapshot)"
else
  fail "missing diff-base should warn and fall back, not fail (exit=${exit_code})"
  cat "${stderr_log}"
fi

echo "=== diff-base guard: unset — clean baseline, no --base anywhere ==="
result="$(run_wrapper)"
exit_code="$(_field "${result}" 1)"
invoke_log="$(_field "${result}" 2)"
stderr_log="$(_field "${result}" 3)"
if [ "${exit_code}" -eq 0 ] \
   && ! grep -q -- "--base" "${invoke_log}" \
   && ! grep -q "diff-base" "${stderr_log}"; then
  pass "no diff-base set: no --base passed, no diff-base diagnostic emitted"
else
  fail "unset diff-base should be a silent no-op (exit=${exit_code})"
  cat "${stderr_log}"
fi

report_and_exit
