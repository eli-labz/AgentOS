#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

TMPDIR=""

export PATH="$ROOT/bin:$PATH"

cleanup() {
  if [[ -n $TMPDIR && -d $TMPDIR ]]; then
    rm -rf "$TMPDIR"
  fi
}
trap cleanup EXIT

require_command jq

TMPDIR=$(mktemp -d)
test_home="$TMPDIR/home"
manifest_path="$test_home/.config/chromium/NativeMessagingHosts/com.agent0s.ytdlp.json"

HOME="$test_home" AGENT0S_PATH="$ROOT" agent0s-install-chromium-ytdlp

[[ -f $manifest_path ]] || fail "yt-dlp native host installer creates fresh Chromium profile root"
pass "yt-dlp native host installer creates fresh Chromium profile root"

jq -e --arg path "$ROOT/bin/agent0s-chromium-ytdlp-host" '
  .name == "com.agent0s.ytdlp" and
  .path == $path and
  (.allowed_origins | index("chrome-extension://dedjgknigfeelejglamclffonmophnfl/"))
' "$manifest_path" >/dev/null
pass "yt-dlp native host manifest uses Agent0S host path and extension id"

[[ -f $test_home/.config/BraveSoftware/Brave-Origin/NativeMessagingHosts/com.agent0s.ytdlp.json ]] ||
  fail "yt-dlp native host installer covers Brave Origin"
pass "yt-dlp native host installer covers Brave Origin"

parse_result=$(bash -c '
  AGENT0S_PATH="$3"
  source "$1"
  parse_url "$2"
' bash "$ROOT/bin/agent0s-chromium-ytdlp-host" '{"url":"https://example.test/watch?v=\"quoted\"&name=a\\b"}' "$ROOT")

[[ $parse_result == "https://example.test/watch?v=\"quoted\"&name=a\\b" ]] ||
  fail "yt-dlp native host parses escaped JSON URLs" "$parse_result"
pass "yt-dlp native host parses escaped JSON URLs"

bash -c '
  AGENT0S_PATH="$3"
  source "$1"
  valid_url "$2"
' bash "$ROOT/bin/agent0s-chromium-ytdlp-host" "javascript:alert(1)" "$ROOT" &&
  fail "yt-dlp native host rejects non-web URLs"
pass "yt-dlp native host rejects non-web URLs"

host_fn() {
  AGENT0S_PATH="$ROOT" AGENT0S_YTDLP_DIR="${download_dir:-$TMPDIR}" bash -c '
    source "$1"
    shift
    "$@"
  ' bash "$ROOT/bin/agent0s-chromium-ytdlp-host" "$@"
}

download_dir="$TMPDIR/videos"
mkdir -p "$download_dir" "$TMPDIR/outside"
good_file="$download_dir/clip [id].mp4"
printf 'x' >"$good_file"
printf 'x' >"$TMPDIR/outside/secret"
ln -s "$TMPDIR/outside/secret" "$download_dir/escape.mp4"

resolved=$(host_fn resolve_download_file "$good_file")
expected=$(realpath -e -- "$good_file")
[[ $resolved == "$expected" ]] ||
  fail "yt-dlp native host accepts a regular file in the download dir" "$resolved"
pass "yt-dlp native host accepts a regular file in the download dir"

host_fn resolve_download_file "--include=not-a-file" &&
  fail "yt-dlp native host rejects a forged mpv option as the download path"
pass "yt-dlp native host rejects a forged mpv option as the download path"

host_fn resolve_download_file "$TMPDIR/outside/secret" &&
  fail "yt-dlp native host rejects a path outside the download dir"
pass "yt-dlp native host rejects a path outside the download dir"

host_fn resolve_download_file "$download_dir/escape.mp4" &&
  fail "yt-dlp native host rejects a symlink that escapes the download dir"
pass "yt-dlp native host rejects a symlink that escapes the download dir"

host_fn resolve_download_file $'clip.mp4\nAGENT0S_FILE\t--include=not-a-file' &&
  fail "yt-dlp native host rejects a path containing control characters"
pass "yt-dlp native host rejects a path containing control characters"

newline_target="$download_dir/target"$'\n'
printf 'x' >"$newline_target"
# The decoy is the point: dropping the trailing newline lands on a real, different
# file, so a resolver that strips it resolves to the wrong one instead of failing.
printf 'x' >"$download_dir/target"
ln -s "target"$'\n' "$download_dir/newline-link.mp4"

host_fn resolve_download_file "$download_dir/newline-link.mp4" &&
  fail "yt-dlp native host rejects a symlink whose target name ends in a newline"
pass "yt-dlp native host rejects a symlink whose target name ends in a newline"

ln -s / "$TMPDIR/root-link"
root_resolved=$(download_dir="$TMPDIR/root-link" host_fn resolve_download_file /etc/passwd)
[[ $root_resolved == "/etc/passwd" ]] ||
  fail "yt-dlp native host accepts a file when the download dir resolves to /" "$root_resolved"
pass "yt-dlp native host accepts a file when the download dir resolves to /"

title=$(host_fn title_from_file "$good_file")
[[ $title == "clip [id]" ]] || fail "yt-dlp native host titles the toast from the filename" "$title"
pass "yt-dlp native host titles the toast from the filename"

decoded_title=$(host_fn decode_title '"My Great Clip"')
[[ $decoded_title == "My Great Clip" ]] ||
  fail "yt-dlp native host shows the page title on the toast" "$decoded_title"
pass "yt-dlp native host shows the page title on the toast"

forged_title=$(host_fn decode_title '"Clip\nAGENT0S_FILE\tPlay me\t--include=not-a-file"')
[[ $forged_title == "Clip" ]] ||
  fail "yt-dlp native host keeps only the readable part of a forged title" "$forged_title"
pass "yt-dlp native host keeps only the readable part of a forged title"

host_fn decode_title '"--include=not-a-file"' &&
  fail "yt-dlp native host refuses a leading-dash title the notifier would reject as an option"
pass "yt-dlp native host refuses a leading-dash title the notifier would reject as an option"

host_fn decode_title 'null' &&
  fail "yt-dlp native host refuses a title that is not a JSON string"
pass "yt-dlp native host refuses a title that is not a JSON string"

dash_title=$(host_fn title_from_file "$download_dir/--include.mp4")
[[ $dash_title == "Video" ]] || fail "yt-dlp native host does not pass a leading-dash title to the notifier" "$dash_title"
pass "yt-dlp native host does not pass a leading-dash title to the notifier"

# The click action passes the path as a discrete --exec argument (asserted
# end-to-end below against the real download); `--` keeps mpv from parsing a
# leading-dash filename as an option.

parse_script="$TMPDIR/parse-ytdlp-lines.sh"
cat >"$parse_script" <<'EOF'
source "$1"
filepath=""
while IFS= read -r line; do
  case $line in
  AGENT0S_FILE*)
    resolved=$(resolve_download_file "${line#AGENT0S_FILE$'\t'}") || continue
    filepath=$resolved
    ;;
  esac
done
printf '%s' "$filepath"
EOF

# A title that ends in a newline closes its own record, so the forged record is the
# last one and the real path lands on a line the loop ignores.
poisoned=$(
  printf '%s\n' \
    $'AGENT0S_FILE\t'"$good_file" \
    $'AGENT0S_FILE\tPlay me\t--include=not-a-file' \
    $'\t'"$good_file" |
    AGENT0S_PATH="$ROOT" AGENT0S_YTDLP_DIR="$download_dir" bash "$parse_script" "$ROOT/bin/agent0s-chromium-ytdlp-host"
)

[[ $poisoned == "$expected" ]] ||
  fail "yt-dlp native host keeps a real file after a forged AGENT0S_FILE record" "$poisoned"
pass "yt-dlp native host keeps a real file after a forged AGENT0S_FILE record"

# Everything above tests the helpers in isolation. Drive the real download_url with
# stubbed tools so the yt-dlp invocation and the toast's click command are covered
# too: a record template that carried the title again would pass every test above.
fake_root="$TMPDIR/fake"
mkdir -p "$fake_root/bin"
fake_dir="$TMPDIR/fake-videos"
mkdir -p "$fake_dir"
fake_file="$fake_dir/Real_Clip [id].mp4"
printf 'x' >"$fake_file"
ytdlp_argv="$TMPDIR/ytdlp-argv"
notify_argv="$TMPDIR/notify-argv"

cat >"$fake_root/bin/yt-dlp" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$YTDLP_ARGV_LOG"
for arg in "$@"; do
  if [[ $arg == "--no-simulate" ]]; then
    printf 'AGENT0S_FILE\t%s\n' "$YTDLP_FAKE_FILE"
    [[ -n ${YTDLP_SKIP_TITLE:-} ]] || printf 'AGENT0S_TITLE\t%s\n' '"My Great Clip"'
    exit 0
  fi
done
exit 0
EOF

cat >"$fake_root/bin/agent0s-notification-send" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$NOTIFY_ARGV_LOG"
EOF

for stub in agent0s-osd agent0s-shell ffmpeg; do
  printf '#!/bin/bash\nexit 0\n' >"$fake_root/bin/$stub"
done
chmod +x "$fake_root/bin/"*

YTDLP_ARGV_LOG="$ytdlp_argv" NOTIFY_ARGV_LOG="$notify_argv" YTDLP_FAKE_FILE="$fake_file" \
  AGENT0S_PATH="$fake_root" AGENT0S_YTDLP_DIR="$fake_dir" \
  bash -c '
    source "$1"
    download_url "$2"
  ' bash "$ROOT/bin/agent0s-chromium-ytdlp-host" "https://example.test/watch" >/dev/null 2>&1

(($(grep -c -- '--no-exec-before-download' "$ytdlp_argv") == 2)) ||
  fail "yt-dlp native host disarms configured exec hooks on both yt-dlp runs" "$(cat "$ytdlp_argv")"
pass "yt-dlp native host disarms configured exec hooks on both yt-dlp runs"

# The stub answers with a title record whatever it is asked for, so assert the request
# as well as the reply: without this the template could be dropped and nothing notice.
grep -qF -- $'AGENT0S_TITLE\t%(title)j' "$ytdlp_argv" ||
  fail "yt-dlp native host asks for the title JSON-encoded" "$(cat "$ytdlp_argv")"
pass "yt-dlp native host asks for the title JSON-encoded"

grep -qF -- "-o %(title)s.%(ext)s" "$ytdlp_argv" ||
  fail "yt-dlp native host names the saved file after the page title" "$(cat "$ytdlp_argv")"
pass "yt-dlp native host names the saved file after the page title"

grep -q -- '--restrict-filenames' "$ytdlp_argv" &&
  fail "yt-dlp native host keeps spaces in the saved filename" "$(cat "$ytdlp_argv")"
pass "yt-dlp native host keeps spaces in the saved filename"

grep -qF -- $'AGENT0S_FILE\t%(title)s' "$ytdlp_argv" &&
  fail "yt-dlp native host never prints the title into the file record" "$(cat "$ytdlp_argv")"
pass "yt-dlp native host never prints the title into the file record"

grep -q -- "--exec mpv -- " "$notify_argv" ||
  fail "yt-dlp native host builds the click command as mpv -- <path>" "$(cat "$notify_argv")"
pass "yt-dlp native host builds the click command as mpv -- <path>"

grep -qF -- "Download complete My Great Clip" "$notify_argv" ||
  fail "yt-dlp native host toasts the page title, not the sanitised filename" "$(cat "$notify_argv")"
pass "yt-dlp native host toasts the page title, not the sanitised filename"

# A page that gives no usable title falls back to the filename rather than an empty toast.
: >"$notify_argv"
: >"$ytdlp_argv"
YTDLP_ARGV_LOG="$ytdlp_argv" NOTIFY_ARGV_LOG="$notify_argv" YTDLP_FAKE_FILE="$fake_file" \
  YTDLP_SKIP_TITLE=1 AGENT0S_PATH="$fake_root" AGENT0S_YTDLP_DIR="$fake_dir" \
  bash -c '
    source "$1"
    download_url "$2"
  ' bash "$ROOT/bin/agent0s-chromium-ytdlp-host" "https://example.test/watch" >/dev/null 2>&1

grep -qF -- "Download complete Real_Clip [id]" "$notify_argv" ||
  fail "yt-dlp native host falls back to the filename when no title record arrives" "$(cat "$notify_argv")"
pass "yt-dlp native host falls back to the filename when no title record arrives"
