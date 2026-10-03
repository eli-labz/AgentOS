#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
log_file="$test_tmp/channel.log"
mkdir -p "$stub_bin" "$test_tmp/home"

write_stub() {
  local name="$1"
  local body="$2"

  cat >"$stub_bin/$name" <<<"$body"
  chmod +x "$stub_bin/$name"
}

write_stub agent0s-refresh-pacman '#!/bin/bash
printf "refresh" >>"$AGENT0S_CHANNEL_TEST_LOG"
for arg in "$@"; do printf "\t%s" "$arg" >>"$AGENT0S_CHANNEL_TEST_LOG"; done
printf "\n" >>"$AGENT0S_CHANNEL_TEST_LOG"
'

write_stub sudo '#!/bin/bash
printf "sudo" >>"$AGENT0S_CHANNEL_TEST_LOG"
for arg in "$@"; do printf "\t%s" "$arg" >>"$AGENT0S_CHANNEL_TEST_LOG"; done
printf "\n" >>"$AGENT0S_CHANNEL_TEST_LOG"
'

write_stub agent0s-update-pacman '#!/bin/bash
printf "update-pacman" >>"$AGENT0S_CHANNEL_TEST_LOG"
for arg in "$@"; do printf "\t%s" "$arg" >>"$AGENT0S_CHANNEL_TEST_LOG"; done
printf "\n" >>"$AGENT0S_CHANNEL_TEST_LOG"
'

write_stub agent0s-dev-unlink '#!/bin/bash
printf "unlink" >>"$AGENT0S_CHANNEL_TEST_LOG"
for arg in "$@"; do printf "\t%s" "$arg" >>"$AGENT0S_CHANNEL_TEST_LOG"; done
printf "\n" >>"$AGENT0S_CHANNEL_TEST_LOG"
'

write_stub agent0s-state '#!/bin/bash
printf "state" >>"$AGENT0S_CHANNEL_TEST_LOG"
for arg in "$@"; do printf "\t%s" "$arg" >>"$AGENT0S_CHANNEL_TEST_LOG"; done
printf "\n" >>"$AGENT0S_CHANNEL_TEST_LOG"
'

write_stub agent0s-update '#!/bin/bash
printf "update" >>"$AGENT0S_CHANNEL_TEST_LOG"
for arg in "$@"; do printf "\t%s" "$arg" >>"$AGENT0S_CHANNEL_TEST_LOG"; done
printf "\tAGENT0S_PATH=%s" "$AGENT0S_PATH" >>"$AGENT0S_CHANNEL_TEST_LOG"
printf "\n" >>"$AGENT0S_CHANNEL_TEST_LOG"
'

write_stub gum '#!/bin/bash
printf "gum" >>"$AGENT0S_CHANNEL_TEST_LOG"
for arg in "$@"; do printf "\t%s" "$arg" >>"$AGENT0S_CHANNEL_TEST_LOG"; done
printf "\n" >>"$AGENT0S_CHANNEL_TEST_LOG"
exit 0
'

write_stub git '#!/bin/bash
printf "git" >>"$AGENT0S_CHANNEL_TEST_LOG"
for arg in "$@"; do printf "\t%s" "$arg" >>"$AGENT0S_CHANNEL_TEST_LOG"; done
printf "\n" >>"$AGENT0S_CHANNEL_TEST_LOG"
if [[ $1 == "clone" ]]; then
  dest="${@: -1}"
  mkdir -p "$dest/.git" "$dest/bin" "$dest/default" "$dest/shell"
fi
'

write_stub agent0s-dev-link '#!/bin/bash
printf "link" >>"$AGENT0S_CHANNEL_TEST_LOG"
for arg in "$@"; do printf "\t%s" "$arg" >>"$AGENT0S_CHANNEL_TEST_LOG"; done
printf "\n" >>"$AGENT0S_CHANNEL_TEST_LOG"
'

write_stub agent0s-version-channel '#!/bin/bash
printf "%s\n" "${AGENT0S_TEST_VERSION_CHANNEL:-unknown}"
'

write_stub pacman '#!/bin/bash
[[ $1 == "-Q" ]] || exit 1
shift
case "${AGENT0S_TEST_PACKAGES:-}" in
  stable) [[ $* == "agent0s agent0s-settings" ]] ;;
  dev) [[ $* == "agent0s-dev agent0s-settings-dev" ]] ;;
  *) exit 1 ;;
esac
'

run_channel() {
  : >"$log_file"
  AGENT0S_CHANNEL_TEST_LOG="$log_file" \
    AGENT0S_PATH="${AGENT0S_TEST_PATH:-/usr/share/agent0s}" \
    HOME="$test_tmp/home" \
    PATH="$stub_bin:$ROOT/bin:$PATH" \
    "$ROOT/bin/agent0s-channel-set" "$@"
}

assert_log_line() {
  local expected="$1"
  local description="$2"

  grep -Fx -- "$expected" "$log_file" >/dev/null || fail "$description" "$(cat "$log_file")"
  pass "$description"
}

run_channel stable
assert_log_line $'refresh\tstable' "stable refreshes the stable pacman channel"
assert_log_line $'update-pacman\t-S\t--needed\t--noconfirm\t--ask\t4\tagent0s\tagent0s-settings' "stable installs stable Agent0S packages"
assert_log_line $'unlink\t--no-reboot' "stable restores the package-backed Agent0S path without an early reboot prompt"
assert_log_line $'update\t-y\tAGENT0S_PATH=/usr/share/agent0s' "stable runs the normal update pipeline from the package-backed path"
if grep -q $'^state\tset\treboot-required$' "$log_file"; then
  fail "stable does not require reboot when already package-backed" "$(cat "$log_file")"
fi
pass "stable does not require reboot when already package-backed"

run_channel rc
assert_log_line $'refresh\trc' "rc refreshes the rc pacman channel"
assert_log_line $'update-pacman\t-S\t--needed\t--noconfirm\t--ask\t4\tagent0s\tagent0s-settings' "rc installs rc Agent0S packages"
assert_log_line $'unlink\t--no-reboot' "rc restores the package-backed Agent0S path without an early reboot prompt"
assert_log_line $'update\t-y\tAGENT0S_PATH=/usr/share/agent0s' "rc runs the normal update pipeline from the package-backed path"

AGENT0S_TEST_PATH="$ROOT" run_channel edge
assert_log_line $'refresh\tedge' "edge refreshes the edge pacman channel"
assert_log_line $'update-pacman\t-S\t--needed\t--noconfirm\t--ask\t4\tagent0s-dev\tagent0s-settings-dev' "edge installs development Agent0S packages"
assert_log_line $'unlink\t--no-reboot' "edge unlinks dev without an early reboot prompt"
assert_log_line $'state\tset\treboot-required' "edge marks reboot required when leaving dev"
assert_log_line $'update\t-y\tAGENT0S_PATH=/usr/share/agent0s' "edge runs the normal update pipeline from the package-backed path"
[[ $(grep -E $'^(unlink|state|update)\t' "$log_file") == $'unlink\t--no-reboot\nstate\tset\treboot-required\nupdate\t-y\tAGENT0S_PATH=/usr/share/agent0s' ]] ||
  fail "edge defers the reboot prompt until the update restart stage" "$(cat "$log_file")"
pass "edge defers the reboot prompt until the update restart stage"

checkout="$test_tmp/home/agent0s"
mkdir -p "$checkout"
if run_channel dev >"$test_tmp/occupied.out" 2>"$test_tmp/occupied.err"; then
  fail "dev refuses to use an occupied non-checkout path"
fi

grep -q "already exists and is not a git checkout" "$test_tmp/occupied.err" || fail "dev explains occupied checkout paths" "$(cat "$test_tmp/occupied.err")"
if grep -Fx $'refresh\tedge' "$log_file" >/dev/null; then
  fail "dev validates checkout path before changing packages" "$(cat "$log_file")"
fi
pass "dev refuses occupied non-checkout paths before package changes"

rmdir "$checkout"
run_channel dev
assert_log_line $'gum\tconfirm\t--default=false\tSwitch to dev channel?' "dev asks for confirmation"
assert_log_line $'refresh\tedge' "dev refreshes the edge pacman channel"
assert_log_line $'update-pacman\t-S\t--needed\t--noconfirm\t--ask\t4\tagent0s-dev\tagent0s-settings-dev' "dev installs development Agent0S packages"
assert_log_line $'git\tclone\thttps://github.com/omacom/omarchy.git\t'"$checkout" "dev clones the source checkout to ~/agent0s"
assert_log_line $'link\t'"$checkout"$'\t--no-reboot' "dev links ~/agent0s without an early reboot prompt"
assert_log_line $'state\tset\treboot-required' "dev defers the reboot prompt to the update pipeline"
assert_log_line $'update\t-y\tAGENT0S_PATH='"$checkout" "dev runs the normal update pipeline from the source checkout"
[[ $(grep -E '^(git|link|state|refresh|sudo|update)' "$log_file") == $'git\tclone\thttps://github.com/omacom/omarchy.git\t'"$checkout"$'\nlink\t'"$checkout"$'\t--no-reboot\nstate\tset\treboot-required\nrefresh\tedge\nupdate-pacman\t-S\t--needed\t--noconfirm\t--ask\t4\tagent0s-dev\tagent0s-settings-dev\nupdate\t-y\tAGENT0S_PATH='"$checkout" ]] ||
  fail "dev activates the checkout before changing or updating packages" "$(cat "$log_file")"
pass "dev activates the checkout before changing or updating packages"

AGENT0S_TEST_PATH="$checkout" run_channel stable
assert_log_line $'unlink\t--no-reboot' "switching from dev to stable unlinks without an early reboot prompt"
assert_log_line $'state\tset\treboot-required' "switching from dev to stable marks reboot required"

run_channel dev
if grep -q $'^git\tclone\t' "$log_file"; then
  fail "dev reuses an existing checkout" "$(cat "$log_file")"
fi
assert_log_line $'link\t'"$checkout"$'\t--no-reboot' "switching back to dev links ~/agent0s"
pass "switching back to dev reuses the existing ~/agent0s checkout"

current_channel() {
  AGENT0S_TEST_VERSION_CHANNEL="$1" \
    AGENT0S_TEST_PACKAGES="$2" \
    AGENT0S_PATH="$3" \
    PATH="$stub_bin:$ROOT/bin:$PATH" \
    "$ROOT/bin/agent0s-channel-current"
}

[[ $(current_channel stable stable /usr/share/agent0s) == "stable" ]] || fail "current channel detects stable"
pass "current channel detects stable"

[[ $(current_channel rc stable /usr/share/agent0s) == "rc" ]] || fail "current channel detects rc"
pass "current channel detects rc"

[[ $(current_channel edge dev /usr/share/agent0s) == "edge" ]] || fail "current channel detects package-backed edge"
pass "current channel detects package-backed edge"

[[ $(current_channel edge dev "$test_tmp/dev-checkout") == "dev" ]] || fail "current channel detects dev from AGENT0S_PATH"
pass "current channel honors a dev link outside ~/agent0s"
