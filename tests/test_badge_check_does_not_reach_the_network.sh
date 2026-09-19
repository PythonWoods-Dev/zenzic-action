#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0
#
# test_badge_check_does_not_reach_the_network.sh — the badge freshness gate must
# pass --no-external when the installed zenzic supports it, and must still run
# when it does not.
#
# Why this exists: `check-stamp` defaults to true, and until v0.31.0 the score it
# runs validated external URLs with no opt-out. Measured in the core repository
# on CI run 35455833729 — the same commit scored 89/100 on one runner and 97 on
# two others, a gap of exactly one Z104 (penalty 8.0), and a re-run with no
# change produced 97 everywhere. Every consumer of this action had that gate.
#
# The support probe reads `zenzic score --help`, so both halves are testable with
# a fake binary: one that advertises the flag and one that does not. The second
# case is the one that matters most — a probe that answers "not supported" when
# it should not would restore the defect in silence.
#
# Usage: bash tests/test_badge_check_does_not_reach_the_network.sh

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER="${REPO_ROOT}/zenzic-action-wrapper.sh"

FAILURES=0
pass() { echo "  PASS: $1"; }
fail() {
  echo "  FAIL: $1"
  FAILURES=$((FAILURES + 1))
}

# $1 = case name, $2 = "yes" if the fake zenzic advertises --no-external
run_case() {
  local name="$1"
  local advertises="$2"

  local workspace
  workspace="$(mktemp -d)"
  local bindir="${workspace}/bin"
  mkdir -p "${bindir}"
  local invoke_log="${workspace}/invocations.log"
  : > "${invoke_log}"

  local help_line=""
  if [ "${advertises}" = "yes" ]; then
    help_line="  --no-external  Skip HTTP validation of external URLs while scoring."
  else
    help_line="  --quiet  Suppress output on successful score."
  fi

  cat > "${bindir}/zenzic" <<STUB
#!/usr/bin/env bash
if [ "\$1" = "score" ] && [ "\$2" = "--help" ]; then
  echo "Usage: zenzic score [OPTIONS] [path]"
  echo "${help_line}"
  exit 0
fi
echo "\$@" >> "${invoke_log}"
case "\$1" in
  check) echo '{"\$schema":"x","version":"2.1.0","runs":[{"tool":{"driver":{"name":"zenzic","rules":[]}},"invocations":[{"executionSuccessful":true}],"results":[]}]}' ;;
  score) echo '{"score":100,"suppression_debt_pts":0,"current_score":100}' ;;
  diff)  echo '{"baseline":100,"current":100,"delta":0,"current_score":100,"suppression_debt_pts":0}' ;;
  audit) echo '{"executive_summary":{"score":100}}' ;;
esac
exit 0
STUB
  chmod +x "${bindir}/zenzic"

  local workdir="${workspace}/checkout"
  mkdir -p "${workdir}"
  local github_output="${workspace}/github_output"
  local github_summary="${workspace}/github_summary"
  : > "${github_output}"
  : > "${github_summary}"

  local exit_code=0
  (
    cd -- "${workdir}"
    export PATH="${bindir}:${PATH}"
    export ZENZIC_VERSION="latest"
    export ZENZIC_FORMAT="sarif"
    export ZENZIC_SARIF_FILE="results.sarif"
    export ZENZIC_STRICT="false"
    export ZENZIC_FAIL_ON_ERROR="true"
    export ZENZIC_AUDIT="false"
    export ZENZIC_DIFF_BASE=""
    export ZENZIC_CHECK_STAMP="true"
    export ZENZIC_CONFIG_FILE=""
    export ZENZIC_GENERATE_AUDIT_REPORT="false"
    export INPUT_WORKING_DIRECTORY="${workdir}"
    export GITHUB_OUTPUT="${github_output}"
    export GITHUB_STEP_SUMMARY="${github_summary}"
    bash "${WRAPPER}" > "${workspace}/stdout.log" 2> "${workspace}/stderr.log"
  ) || exit_code=$?

  echo "${name}|${exit_code}|${invoke_log}|${workspace}/stdout.log"
}

echo "=== badge gate: zenzic supports --no-external ==="
result=$(run_case "supported" "yes")
exit_code=$(echo "${result}" | cut -d'|' -f2)
invoke_log=$(echo "${result}" | cut -d'|' -f3)
if [ "${exit_code}" -eq 0 ] && grep -q -- "score --check-stamp --ci --no-external" "${invoke_log}"; then
  pass "--no-external reaches 'score --check-stamp'"
else
  fail "the badge gate should have passed --no-external (exit=${exit_code})"
  cat "${invoke_log}" 2>/dev/null || echo "(no invocation log)"
fi

echo "=== badge gate: older zenzic without the flag still runs, and says so ==="
result=$(run_case "unsupported" "no")
exit_code=$(echo "${result}" | cut -d'|' -f2)
invoke_log=$(echo "${result}" | cut -d'|' -f3)
stdout_log=$(echo "${result}" | cut -d'|' -f4)
if [ "${exit_code}" -eq 0 ] \
  && grep -q -- "score --check-stamp --ci" "${invoke_log}" \
  && ! grep -q -- "--no-external" "${invoke_log}" \
  && grep -q "Badge check reaches the network" "${stdout_log}"; then
  pass "the gate still runs, without the flag, and the limitation is stated"
else
  fail "an older zenzic should run the gate unchanged and emit the notice (exit=${exit_code})"
  cat "${invoke_log}" 2>/dev/null || echo "(no invocation log)"
  cat "${stdout_log}" 2>/dev/null || echo "(no stdout log)"
fi

echo
if [ "${FAILURES}" -eq 0 ]; then
  echo "ALL PASSED"
  exit 0
else
  echo "${FAILURES} FAILURE(S)"
  exit 1
fi
