#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0
#
# guard_harness.sh — shared harness for the wrapper's path-sandbox guard tests.
#
# Every sandbox guard in zenzic-action-wrapper.sh (sarif-file, diff-base,
# config-file) rejects the same two input classes with the same shape: an
# absolute path, and a path containing a `..` traversal sequence. Those two
# branches were being re-implemented per test file. This harness holds them
# once, so a new guard's test is the guard-specific behaviour plus two calls.
#
# Sourced, never executed:
#
#     source "$(dirname "${BASH_SOURCE[0]}")/lib/guard_harness.sh"
#
# Like tests/test_config_file_guard.sh, this runs the REAL wrapper against a
# fake `zenzic` on PATH — no network, no uv install — and asserts real exit
# codes and real invocation arguments rather than re-implementing guard logic.

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
WRAPPER="${REPO_ROOT}/zenzic-action-wrapper.sh"

FAILURES=0

pass() { echo "  PASS: $1"; }
fail() {
  echo "  FAIL: $1"
  FAILURES=$((FAILURES + 1))
}

# run_wrapper <env-assignment>... — run the real wrapper in a throwaway
# workspace with a fake `zenzic` on PATH. Each argument is a literal
# NAME=VALUE applied on top of the neutral defaults below, so a caller sets
# only the variable its guard is about.
#
# The pseudo-assignment HARNESS_PRECREATE_DIR=<relpath> is consumed by the
# harness rather than exported: it mkdir -p's that path inside the checkout
# before the wrapper runs. Needed because the wrapper redirects analyzer output
# into ${ZENZIC_SARIF_FILE} without creating its parent directory, so a nested
# output path fails on the redirect for reasons that have nothing to do with
# the guard under test. Pre-creating the directory isolates the guard.
#
# Echoes: <exit_code>|<invocation_log>|<stderr_log>|<workdir>
run_wrapper() {
  local workspace bindir invoke_log workdir github_output github_summary
  workspace="$(mktemp -d)"
  bindir="${workspace}/bin"
  workdir="${workspace}/checkout"
  invoke_log="${workspace}/invocations.log"
  github_output="${workspace}/github_output"
  github_summary="${workspace}/github_summary"
  mkdir -p "${bindir}" "${workdir}"
  : > "${invoke_log}" ; : > "${github_output}" ; : > "${github_summary}"

  # Consume HARNESS_PRECREATE_DIR out of the argument list (see above).
  local passthrough=() arg
  for arg in "$@"; do
    case "${arg}" in
      HARNESS_PRECREATE_DIR=*) mkdir -p "${workdir}/${arg#HARNESS_PRECREATE_DIR=}" ;;
      *) passthrough+=("${arg}") ;;
    esac
  done
  set -- ${passthrough+"${passthrough[@]}"}

  # Fake `zenzic`: logs every invocation, emits the minimum each subcommand's
  # parser needs, always exits 0 — so a non-zero result can only come from the
  # wrapper's own guards, never from the analyzer.
  cat > "${bindir}/zenzic" <<STUB
#!/usr/bin/env bash
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

  local exit_code=0
  (
    # Guard existence checks run before the wrapper's own `cd` into
    # INPUT_WORKING_DIRECTORY, matching real Action semantics where the step's
    # CWD is already github.workspace.
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
    export ZENZIC_CONFIG_FILE=""
    export ZENZIC_GENERATE_AUDIT_REPORT="false"
    export INPUT_WORKING_DIRECTORY="${workdir}"
    export GITHUB_OUTPUT="${github_output}"
    export GITHUB_STEP_SUMMARY="${github_summary}"
    local kv
    for kv in "$@"; do export "${kv?}"; done
    bash "${WRAPPER}" > "${workspace}/stdout.log" 2> "${workspace}/stderr.log"
  ) || exit_code=$?

  echo "${exit_code}|${invoke_log}|${workspace}/stderr.log|${workdir}"
}

_field() { echo "$1" | cut -d'|' -f"$2"; }

# assert_rejected <label> <error-marker> <env-assignment>... — the guard must
# exit 1 and name itself in the error. Used for both shared rejection branches.
assert_rejected() {
  local label="$1" marker="$2"; shift 2
  local result exit_code stderr_log
  result="$(run_wrapper "$@")"
  exit_code="$(_field "${result}" 1)"
  stderr_log="$(_field "${result}" 3)"
  if [ "${exit_code}" -eq 1 ] && grep -q "${marker}" "${stderr_log}"; then
    pass "${label}"
  else
    fail "${label} (expected exit 1 + '${marker}', got exit ${exit_code})"
    cat "${stderr_log}"
  fi
}

# assert_rejects_absolute_and_traversal <input-var> <error-marker> <guard-name>
# The two branches every path guard shares, asserted in one call.
assert_rejects_absolute_and_traversal() {
  local var="$1" marker="$2" guard="$3"
  assert_rejected "${guard}: absolute path '/etc/passwd' rejected" "${marker}" "${var}=/etc/passwd"
  assert_rejected "${guard}: traversal '../../../etc/passwd' rejected" "${marker}" "${var}=../../../etc/passwd"
}

report_and_exit() {
  echo
  if [ "${FAILURES}" -eq 0 ]; then
    echo "ALL PASSED"
    exit 0
  fi
  echo "${FAILURES} FAILURE(S)"
  exit 1
}
