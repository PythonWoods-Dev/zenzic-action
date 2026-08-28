#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0
#
# test_config_file_guard.sh — Real-execution test coverage for the config-file
# sandbox guard in zenzic-action-wrapper.sh (accept + reject paths).
#
# Runs the ACTUAL wrapper script against a fake `zenzic` binary on PATH (so no
# network/uv install is needed), asserting real exit codes and real invocation
# arguments — not a reimplementation of the guard logic. Mirrors the existing
# manual verification approach used elsewhere in this repo (no bats/shell test
# framework is currently wired up).
#
# Usage: bash tests/test_config_file_guard.sh
# Exits 0 if every case passes, 1 on the first failure.

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER="${REPO_ROOT}/zenzic-action-wrapper.sh"

FAILURES=0

pass() { echo "  PASS: $1"; }
fail() {
  echo "  FAIL: $1"
  FAILURES=$((FAILURES + 1))
}

run_case() {
  # $1 = case name, $2 = ZENZIC_CONFIG_FILE value, $3 = "create" to pre-create
  # the file on disk, anything else (or omitted) to leave it absent.
  local name="$1"
  local config_file="$2"
  local precreate="${3:-}"

  local workspace
  workspace="$(mktemp -d)"
  # Not cleaned up automatically — each workspace is small and OS tmp
  # cleanup handles it eventually; callers may inspect logs after the run.

  local bindir="${workspace}/bin"
  mkdir -p "${bindir}"
  local invoke_log="${workspace}/invocations.log"
  : > "${invoke_log}"

  # Fake `zenzic` binary: logs every invocation, emits just enough output for
  # the wrapper's own parsing logic (SARIF/JSON) to succeed, always exits 0.
  cat > "${bindir}/zenzic" <<STUB
#!/usr/bin/env bash
echo "\$@" >> "${invoke_log}"
case "\$1" in
  check)
    echo '{"\$schema":"x","version":"2.1.0","runs":[{"tool":{"driver":{"name":"zenzic","rules":[]}},"invocations":[{"executionSuccessful":true}],"results":[]}]}'
    ;;
  score)
    echo '{"score":100,"suppression_debt_pts":0,"current_score":100}'
    ;;
  diff)
    echo '{"baseline":100,"current":100,"delta":0,"current_score":100,"suppression_debt_pts":0}'
    ;;
  audit)
    echo '{"executive_summary":{"score":100}}'
    ;;
esac
exit 0
STUB
  chmod +x "${bindir}/zenzic"

  local workdir="${workspace}/checkout"
  mkdir -p "${workdir}"
  if [ "${precreate}" = "create" ]; then
    mkdir -p "$(dirname -- "${workdir}/${config_file}")"
    echo 'docs_dir = "."' > "${workdir}/${config_file}"
  fi

  local github_output="${workspace}/github_output"
  local github_summary="${workspace}/github_summary"
  : > "${github_output}"
  : > "${github_summary}"

  local exit_code=0
  (
    # The guard's [ -f ... ] existence check runs before the wrapper's own
    # `cd -- "${INPUT_WORKING_DIRECTORY}"` — matching real Action semantics
    # where the step's CWD is already github.workspace. Mirror that here by
    # cd-ing into the same directory INPUT_WORKING_DIRECTORY points at.
    cd -- "${workdir}"
    export PATH="${bindir}:${PATH}"
    export ZENZIC_VERSION="latest"
    export ZENZIC_FORMAT="sarif"
    export ZENZIC_SARIF_FILE="results.sarif"
    export ZENZIC_STRICT="false"
    export ZENZIC_FAIL_ON_ERROR="true"
    export ZENZIC_AUDIT="false"
    export ZENZIC_DIFF_BASE=""
    export ZENZIC_CHECK_STAMP="false"
    export ZENZIC_CONFIG_FILE="${config_file}"
    export ZENZIC_GENERATE_AUDIT_REPORT="false"
    export INPUT_WORKING_DIRECTORY="${workdir}"
    export GITHUB_OUTPUT="${github_output}"
    export GITHUB_STEP_SUMMARY="${github_summary}"
    bash "${WRAPPER}" > "${workspace}/stdout.log" 2> "${workspace}/stderr.log"
  ) || exit_code=$?

  echo "${name}|${exit_code}|${invoke_log}|${workspace}/stderr.log"
}

echo "=== config-file guard: reject absolute path ==="
result=$(run_case "absolute" "/etc/passwd" "")
exit_code=$(echo "${result}" | cut -d'|' -f2)
stderr_log=$(echo "${result}" | cut -d'|' -f4)
if [ "${exit_code}" -eq 1 ] && grep -q "config-file Jailbreak" "${stderr_log}"; then
  pass "absolute path '/etc/passwd' rejected with exit 1 and Jailbreak error"
else
  fail "absolute path should have been rejected (exit=${exit_code})"
  cat "${stderr_log}"
fi

echo "=== config-file guard: reject path traversal ==="
result=$(run_case "traversal" "../../../etc/passwd" "")
exit_code=$(echo "${result}" | cut -d'|' -f2)
stderr_log=$(echo "${result}" | cut -d'|' -f4)
if [ "${exit_code}" -eq 1 ] && grep -q "config-file Jailbreak" "${stderr_log}"; then
  pass "traversal path '../../../etc/passwd' rejected with exit 1 and Jailbreak error"
else
  fail "traversal path should have been rejected (exit=${exit_code})"
  cat "${stderr_log}"
fi

echo "=== config-file guard: reject nonexistent relative path ==="
result=$(run_case "missing" "configs/does-not-exist.toml" "")
exit_code=$(echo "${result}" | cut -d'|' -f2)
stderr_log=$(echo "${result}" | cut -d'|' -f4)
if [ "${exit_code}" -eq 1 ] && grep -q "config-file Not Found" "${stderr_log}"; then
  pass "nonexistent config-file rejected with exit 1 and Not Found error"
else
  fail "nonexistent config-file should have been rejected (exit=${exit_code})"
  cat "${stderr_log}"
fi

echo "=== config-file guard: accept valid relative path, threaded to zenzic ==="
result=$(run_case "accept" "configs/prod.toml" "create")
exit_code=$(echo "${result}" | cut -d'|' -f2)
invoke_log=$(echo "${result}" | cut -d'|' -f3)
if [ "${exit_code}" -eq 0 ] && [ -s "${invoke_log}" ] && ! grep -qv -- "--config configs/prod.toml" "${invoke_log}"; then
  pass "valid config-file accepted, '--config configs/prod.toml' present on every zenzic invocation"
else
  fail "valid config-file should have been threaded to every zenzic call (exit=${exit_code})"
  cat "${invoke_log}" 2>/dev/null || echo "(no invocation log)"
fi

echo "=== config-file guard: unset — no --config passed, unaffected baseline ==="
result=$(run_case "unset" "" "")
exit_code=$(echo "${result}" | cut -d'|' -f2)
invoke_log=$(echo "${result}" | cut -d'|' -f3)
if [ "${exit_code}" -eq 0 ] && [ -s "${invoke_log}" ] && ! grep -q -- "--config" "${invoke_log}"; then
  pass "no config-file set: '--config' absent from every zenzic invocation (baseline unaffected)"
else
  fail "baseline (no config-file) should not pass --config anywhere"
  cat "${invoke_log}" 2>/dev/null || echo "(no invocation log)"
fi

echo
if [ "${FAILURES}" -eq 0 ]; then
  echo "ALL PASSED"
  exit 0
else
  echo "${FAILURES} FAILURE(S)"
  exit 1
fi
