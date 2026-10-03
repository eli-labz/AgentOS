#!/bin/bash

set -euo pipefail

# agent0s-theme-install feeds a pasted URL to git and a name derived from it to
# rm, and agent0s-theme-remove feeds its argument to rm. Both are exercised here
# with git and the themes directory stubbed, so a guard that stopped working
# shows up as a clone or a removal that should never have been reached.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/git" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$AGENT0S_TEST_GIT_CALLS"
[[ $1 == "clone" ]] && mkdir -p "${*: -1}"
exit 0
SH

cat >"$mock_bin/gum" <<'SH'
#!/bin/bash
exit 1
SH

for command in agent0s-theme-set agent0s-notification-send agent0s-menu-select; do
  printf '#!/bin/bash\nprintf "%%s\\n" "$*" >>"$AGENT0S_TEST_THEME_CALLS"\nexit 0\n' >"$mock_bin/$command"
done

chmod +x "$mock_bin"/*

git_calls="$test_tmp/git-calls"
theme_calls="$test_tmp/theme-calls"

install_theme() {
  : >"$git_calls"
  : >"$theme_calls"

  HOME="$test_tmp/home" PATH="${2-$mock_bin:$ROOT/bin:$PATH}" \
    AGENT0S_TEST_GIT_CALLS="$git_calls" AGENT0S_TEST_THEME_CALLS="$theme_calls" \
    bash "$ROOT/bin/agent0s-theme-install" "$1" >"$test_tmp/out" 2>&1 || return $?
}

mkdir -p "$test_tmp/home/.config/agent0s/themes"

# A URL git would read as an option or as a remote helper to run.
for url in "-x" "--upload-pack=touch /tmp/pwned" "ext::sh -c id" "fd::0,1"; do
  if install_theme "$url"; then
    fail "agent0s-theme-install refuses the URL '$url'"
  fi

  [[ ! -s $git_calls ]] || fail "agent0s-theme-install refuses '$url' before running git" "$(cat "$git_calls")"
done

pass "a URL that names a git option or a transport helper never reaches git"

# git resolves git-remote-<scheme> for any scheme it does not implement itself,
# so the `://` spelling of a helper has to be refused as well as the `::` one.
for url in "ext://sh -c id" "fd://17" "gcrypt://example.com/x"; do
  if install_theme "$url"; then
    fail "agent0s-theme-install refuses the URL '$url'"
  fi

  [[ ! -s $git_calls ]] || fail "agent0s-theme-install refuses '$url' before running git" "$(cat "$git_calls")"
done

pass "a URL naming a transport git does not implement never reaches git"

# The checker is a separate command, so its absence has to refuse the URL rather
# than wave it through to git. Installed machines carry the packaged checker in
# /usr/bin, so absence is simulated by shadowing it with a stub that reports
# command-not-found instead of thinning the PATH.
missing_checker_bin="$test_tmp/missing-checker-bin"
mkdir -p "$missing_checker_bin"
printf '#!/bin/bash\nexit 127\n' >"$missing_checker_bin/agent0s-git-url-check"
chmod +x "$missing_checker_bin/agent0s-git-url-check"

if install_theme "https://github.com/example/omarchy-cool-theme.git" "$missing_checker_bin:$mock_bin:$ROOT/bin:$PATH"; then
  fail "agent0s-theme-install refuses a URL it cannot check"
fi

[[ ! -s $git_calls ]] ||
  fail "agent0s-theme-install refuses an unchecked URL before running git" "$(cat "$git_calls")"

pass "a missing url checker refuses the URL instead of cloning it"

# A URL whose derived name would escape the themes directory.
for url in "https://example.com/..git" "https://example.com/.git"; do
  if install_theme "$url"; then
    fail "agent0s-theme-install refuses the derived name from '$url'"
  fi

  [[ ! -s $git_calls ]] || fail "agent0s-theme-install refuses '$url' before running git" "$(cat "$git_calls")"
done

pass "a URL whose name would climb out of the themes directory never reaches git"

# The derived name outlives the clone: it is the theme's directory name, and
# Style > Unlock builds a command line out of the name the picker returned. A
# repo whose name carries shell syntax would hand that picker its own command,
# so the name is refused here rather than quoted at each place it lands.
for url in \
  "https://example.com/agent0s-a';id;'b-theme.git" \
  'https://example.com/a$(id).git' \
  'https://example.com/a`id`.git' \
  "https://example.com/a b.git" \
  "https://example.com/-a.git"; do
  if install_theme "$url"; then
    fail "agent0s-theme-install refuses the derived name from '$url'"
  fi

  [[ ! -s $git_calls ]] || fail "agent0s-theme-install refuses '$url' before running git" "$(cat "$git_calls")"
done

pass "a URL whose name would be shell syntax never reaches git"

# And the check is an allowlist, so the punctuation a real theme name uses has
# to keep working.
install_theme "https://github.com/example/omarchy-tokyo_night.2-theme.git" ||
  fail "agent0s-theme-install accepts the punctuation a theme name uses"
grep -Fq "/themes/tokyo_night.2" "$git_calls" ||
  fail "agent0s-theme-install derives a name carrying an underscore and a dot" "$(cat "$git_calls")"

pass "a theme name may still hold an underscore, a dot, and a dash"

# A plus is neither path-climb nor shell syntax, and a leading underscore is
# neither the `..` climb nor the dash that reads as an option, so the allowlist
# keeps both rather than stranding a repo that names itself with them.
install_theme "https://github.com/example/omarchy-c++-theme.git" ||
  fail "agent0s-theme-install accepts a name holding a plus"
grep -Fq "/themes/c++" "$git_calls" ||
  fail "agent0s-theme-install derives a name carrying a plus" "$(cat "$git_calls")"

install_theme "https://github.com/example/_private.git" ||
  fail "agent0s-theme-install accepts a name starting with an underscore"
grep -Fq "/themes/_private" "$git_calls" ||
  fail "agent0s-theme-install derives a name starting with an underscore" "$(cat "$git_calls")"

pass "a plus and a leading underscore are still usable theme names"

# git reads a colon before any slash as the scp-style separator, so the path
# after it does not have to hold one. Without that reading, the whole URL becomes
# the theme name and the allowlist above refuses a repo that clones fine.
install_theme "git@example.com:agent0s-blue-theme.git" ||
  fail "agent0s-theme-install accepts a home-relative scp-style URL"
grep -Fq "/themes/blue" "$git_calls" ||
  fail "agent0s-theme-install names the theme after the repo, not the whole URL" "$(cat "$git_calls")"

# A colon that is part of a local path, not an scp separator, keeps its prefix.
install_theme "/srv/git:mirrors/agent0s-blue-theme.git" ||
  fail "agent0s-theme-install accepts a local path holding a colon"
grep -Fq "/themes/blue" "$git_calls" ||
  fail "agent0s-theme-install reads a colon after a slash as part of the path" "$(cat "$git_calls")"

pass "an scp-style URL with no slash after the colon still names the theme"

# The allowlist is a bracket range, and a range follows the locale's collation
# rather than ASCII: under en_US.UTF-8 an unpinned `[a-z]` takes in `é`, so the
# same URL would install on one desktop and be refused on the next.
if locale -a 2>/dev/null | grep -qix 'en_US.utf-\?8'; then
  for locale_name in C en_US.UTF-8; do
    if LC_ALL=$locale_name install_theme "https://github.com/example/omarchy-café-theme.git"; then
      fail "agent0s-theme-install refuses a non-ASCII theme name under LC_ALL=$locale_name" "$(cat "$git_calls")"
    fi

    [[ ! -s $git_calls ]] ||
      fail "agent0s-theme-install refuses a non-ASCII name before running git" "$(cat "$git_calls")"
  done

  pass "the accepted set does not move with the desktop's locale"
else
  pass "no en_US.UTF-8 locale; skipping the locale-pinning check"
fi

# basename reads a leading dash as an option once the scp-style prefix is gone.
install_theme "host:-s/foo.git" || fail "agent0s-theme-install accepts a normal scp-style URL"
grep -Fq -- "-- host:-s/foo.git" "$git_calls" || fail "agent0s-theme-install passes the URL after --" "$(cat "$git_calls")"
grep -Fq "/themes/foo" "$git_calls" || fail "agent0s-theme-install derives 'foo', not '.git'" "$(cat "$git_calls")"

pass "a dash inside the path does not become a basename option"

# And the ordinary case still works.
install_theme "https://github.com/example/omarchy-cool-theme.git" || fail "agent0s-theme-install clones a normal URL"
grep -Fq "/themes/cool" "$git_calls" || fail "agent0s-theme-install derives the theme name" "$(cat "$git_calls")"
grep -Fxq "cool" "$theme_calls" || fail "agent0s-theme-install applies the theme it installed" "$(cat "$theme_calls")"

pass "an ordinary theme URL still clones and applies"

# agent0s-theme-remove joins its argument into the path it deletes.
remove_theme() {
  : >"$theme_calls"

  HOME="$test_tmp/home" PATH="$mock_bin:$PATH" AGENT0S_TEST_THEME_CALLS="$theme_calls" \
    bash "$ROOT/bin/agent0s-theme-remove" "$1" >"$test_tmp/out" 2>&1 || return $?
}

canary="$test_tmp/home/.config/agent0s/canary"
printf 'still here\n' >"$canary"

for name in ".." "." "../../evil" ".git"; do
  if remove_theme "$name"; then
    fail "agent0s-theme-remove refuses the theme name '$name'"
  fi

  [[ -f $canary ]] || fail "agent0s-theme-remove refuses '$name' before removing anything"
done

pass "a theme name cannot climb out of the themes directory on the way to rm"
