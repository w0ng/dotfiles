#!/bin/bash
#
# Shared test harness: counters, assertions and the runner.
#
# Every tests/*_test.sh sources this. A suite supplies its own `setup` and
# `teardown`, then calls `main` once its test functions are defined. run_test
# invokes setup and teardown by name, and main finds tests with compgen, so both
# have to run after the suite's own definitions.
#
# Sourcing this also sets shell options, because every suite wants the same
# ones. A suite that needs them relaxed inside a test relaxes them there.
#
# No test framework. This is the part two suites already shared, and one copy is
# what stops them drifting.

set -uo pipefail

# The sourcing suite reads REPO_ROOT and WORK_DIR, not this file, and the
# linter cannot follow a use across the source boundary.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
readonly REPO_ROOT

TESTS_RUN=0
FAILURES=0
STUB_LOG=''
# shellcheck disable=SC2034
WORK_DIR=''

fail() {
  printf '  FAIL: %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

assert_eq() {
  local expected="$1" actual="$2" what="$3"
  if [[ "${expected}" != "${actual}" ]]; then
    fail "${what}: expected [${expected}], got [${actual}]"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" what="$3"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    fail "${what}: [${needle}] not found in [${haystack}]"
  fi
}

assert_not_contains() {
  local haystack="$1" needle="$2" what="$3"
  if [[ "${haystack}" == *"${needle}"* ]]; then
    fail "${what}: [${needle}] unexpectedly present"
  fi
}

assert_success() {
  local status="$1" what="$2"
  ((status == 0)) || fail "${what}: expected success, got status ${status}"
}

assert_failure() {
  local status="$1" what="$2"
  ((status != 0)) || fail "${what}: expected failure, got success"
}

# Runs a single test function in a subshell, so sourcing and globals cannot
# leak between cases.
run_test() {
  local name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  printf '• %s\n' "${name}"
  # shellcheck disable=SC2030,SC2031 # FAILURES is deliberately subshell-local;
  # the subshell reports its count through the exit status instead.
  (
    # Reset inside the subshell, because it inherits the running total, and
    # exiting with that would make every test after the first failure look
    # failed too.
    FAILURES=0
    setup
    "${name}"
    teardown
    exit "${FAILURES}"
  ) || FAILURES=$((FAILURES + 1))
}

calls() {
  cat "${STUB_LOG}"
}

main() {
  local name
  for name in $(compgen -A function test_); do
    run_test "${name}"
  done

  printf '\n%d test(s), %d failure(s)\n' "${TESTS_RUN}" "${FAILURES}"
  ((FAILURES == 0))
}
