#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/agent0s-cmd-present" <<'SH'
#!/bin/bash
[[ ${AGENT0S_TEST_INSTALLED:-false} == "true" ]]
SH

cat >"$mock_bin/setsid" <<'SH'
#!/bin/bash
shift
printf 'launch:%s\n' "$*" >"$AGENT0S_TEST_LOG"
SH

cat >"$mock_bin/agent0s-launch-floating-terminal-with-presentation" <<'SH'
#!/bin/bash
printf 'install:%s\n' "$*" >"$AGENT0S_TEST_LOG"
SH

chmod +x "$mock_bin"/*

launch_log="$test_tmp/launch-log"
PATH="$mock_bin:$PATH" AGENT0S_TEST_INSTALLED=true AGENT0S_TEST_LOG="$launch_log" \
  bash "$ROOT/bin/agent0s-launch-1password"
grep -Fxq 'launch:-- 1password --force-device-scale-factor=1' "$launch_log" ||
  fail "1Password launcher starts the installed app at a fixed scale factor"
pass "1Password launcher starts the installed app at a fixed scale factor"

PATH="$mock_bin:$PATH" AGENT0S_TEST_INSTALLED=false AGENT0S_TEST_LOG="$launch_log" \
  bash "$ROOT/bin/agent0s-launch-1password"
grep -Fxq 'install:agent0s-install-service-1password' "$launch_log" ||
  fail "1Password launcher starts the installer when missing"
pass "1Password launcher starts the installer when missing"

grep -Fq '{ agent0s = "1password" }' "$ROOT/default/hypr/bindings/applications.lua" ||
  fail "1Password keybinding uses the conditional launcher"
pass "1Password keybinding uses the conditional launcher"
