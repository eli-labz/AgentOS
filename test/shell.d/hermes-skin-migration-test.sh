#!/bin/bash

set -euo pipefail

# The migration hands an existing Hermes Desktop install the Agent0S skin. It
# is exercised here with the package probe and the skin hook stubbed, so a
# migration that reached a Hermes Agent0S did not install, or that marked a
# failed hand-over done, shows up in what it ran.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

migration="$ROOT/migrations/1788619462.sh"
[[ -f $migration ]] || fail "Hermes skin migration exists"
[[ $(stat -c %a "$migration") == "644" ]] || fail "migration is a plain 0644 file"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
calls="$test_tmp/calls"
mkdir -p "$mock_bin"

cat >"$mock_bin/agent0s-pkg-present" <<'SH'
#!/bin/bash
[[ $1 == "hermes-desktop" && ${AGENT0S_TEST_DESKTOP_INSTALLED:-0} == 1 ]]
SH

cat >"$mock_bin/agent0s-theme-set-hermes" <<'SH'
#!/bin/bash
echo "agent0s-theme-set-hermes $*" >>"$AGENT0S_TEST_CALLS"
[[ ${AGENT0S_TEST_HOOK_FAILS:-0} == 0 ]]
SH

chmod +x "$mock_bin"/*

run_migration() {
  : >"$calls"
  AGENT0S_TEST_DESKTOP_INSTALLED="${AGENT0S_TEST_DESKTOP_INSTALLED:-1}" \
    AGENT0S_TEST_HOOK_FAILS="${AGENT0S_TEST_HOOK_FAILS:-0}" \
    AGENT0S_TEST_CALLS="$calls" \
    PATH="$mock_bin:$PATH" \
    HOME="$test_tmp/home" \
    AGENT0S_PATH="$ROOT" \
    bash -euo pipefail "$migration" >/dev/null
}

AGENT0S_TEST_DESKTOP_INSTALLED=0 run_migration || fail "migration exits clean without Hermes Desktop"
[[ ! -s $calls ]] || fail "a machine without Hermes Desktop is left alone" "$(cat "$calls")"
pass "migration only applies where Agent0S installed Hermes Desktop"

run_migration || fail "migration exits clean with Hermes Desktop installed"
[[ $(cat "$calls") == "agent0s-theme-set-hermes --activate" ]] ||
  fail "the skin is rendered, published and activated through the hook's deliberate form" "$(cat "$calls")"
pass "migration hands the skin over through the hook"

if AGENT0S_TEST_HOOK_FAILS=1 run_migration; then
  fail "a hand-over that failed on Agent0S's side stays pending"
fi
pass "migration stays pending when the hand-over fails"
