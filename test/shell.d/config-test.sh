#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

export PATH="$ROOT/bin:$PATH"

require_command jq
require_command lua
require_command python3

jq empty "$ROOT/config/agent0s/shell.json"
pass "default shell.json is valid JSON"

jq -e '.version == 1 and (.bar.layout.left | type == "array") and (.bar.layout.center | type == "array") and (.bar.layout.right | type == "array")' "$ROOT/config/agent0s/shell.json" >/dev/null
pass "default shell.json has versioned bar layout"

# Pinning the whole row made this fail every time an unrelated widget moved,
# so assert the adjacency the name is about and let the rest of the row change.
jq -e '
  def ids: map(.id // .);
  (.bar.layout.center | ids) as $ids |
  ($ids | index("agent0s.weather")) as $weather |
  ($ids | index("agent0s.system-update")) as $update |
  $weather != null and $update == $weather + 1
' "$ROOT/config/agent0s/shell.json" >/dev/null
pass "default center layout keeps update next to weather"

jq -e '
  (.bar.centerAnchor // "") as $anchor |
  any(.bar.layout.center[]; (.id // .) == $anchor)
' "$ROOT/config/agent0s/shell.json" >/dev/null
pass "default center anchor exists in center layout"

jq -e '
  any(.bar.layout.center[]; (.id // .) == "agent0s.clock" and (.formatAlt // "") == "d MMMM \u0027W\u0027ww yyyy")
' "$ROOT/config/agent0s/shell.json" >/dev/null
pass "default clock date format has no leading zero"

jq -e '
  def ids: map(.id // .);
  (.bar.layout.right | ids) as $ids |
  ($ids | index("agent0s.tray")) as $tray |
  ($ids | index("agent0s.agents")) as $agents |
  $tray != null and $agents == $tray + 1
' "$ROOT/config/agent0s/shell.json" >/dev/null
pass "default right layout keeps agents next to the tray"

ROOT="$ROOT" python3 <<'PY'
import json
import os
import sys
from pathlib import Path

root = Path(os.environ["ROOT"])
config = json.loads((root / "config/agent0s/shell.json").read_text())
manifests = {}
for manifest_path in (root / "shell/plugins").glob("**/*.manifest.json"):
  data = json.loads(manifest_path.read_text())
  manifests[data.get("id", "")] = (manifest_path, data)
for manifest_path in (root / "shell/plugins").glob("**/manifest.json"):
  data = json.loads(manifest_path.read_text())
  manifests[data.get("id", "")] = (manifest_path, data)

entries = []
for section in ("left", "center", "right"):
  entries.extend(config["bar"]["layout"][section])

missing = []
bad = []
for entry in entries:
  widget_id = entry["id"] if isinstance(entry, dict) else str(entry)
  if not widget_id.startswith("agent0s."):
    continue

  row = manifests.get(widget_id)
  if row is None:
    missing.append(widget_id)
    continue
  manifest_path, manifest = row

  if "bar-widget" not in manifest.get("kinds", []):
    bad.append(f"{widget_id}: missing bar-widget kind")
  entry_point = manifest.get("entryPoints", {}).get("barWidget")
  if not entry_point:
    bad.append(f"{widget_id}: missing barWidget entry point")
  elif not (manifest_path.parent / entry_point).exists():
    bad.append(f"{widget_id}: missing {entry_point}")

if missing or bad:
  for item in missing:
    print(f"missing manifest for {item}", file=sys.stderr)
  for item in bad:
    print(item, file=sys.stderr)
  sys.exit(1)
PY
pass "default bar widget ids resolve to manifests and entry points"

ROOT="$ROOT" python3 <<'PY'
import os
import sys
from pathlib import Path

root = Path(os.environ["ROOT"])
home = Path.home()
pkgs_candidates = [
  root.parent / "omarchy-pkgs/pkgbuilds",
  root.parent / "agent0s/omarchy-pkgs/pkgbuilds",
  root.parent.parent / "omarchy-pkgs/pkgbuilds",
  root.parent / "omacom/omarchy-pkgs/pkgbuilds",
  root.parent.parent / "omacom/omarchy-pkgs/pkgbuilds",
  home / "Work/omacom/omarchy-pkgs/pkgbuilds",
]
# Checkouts differ per machine, so allow an explicit pointer at the sibling repo.
# Accepts either the omarchy-pkgs checkout or its pkgbuilds/ directory.
override = os.environ.get("AGENT0S_PKGS_PATH")
if override:
  pkgs_candidates = [Path(override) / "pkgbuilds", Path(override)] + pkgs_candidates
pkgs_root = next((path for path in pkgs_candidates if path.exists()), None)
if pkgs_root is None:
  print("not ok - omarchy-pkgs checkout found for PKGBUILD coverage", file=sys.stderr)
  print(
    "looked in:\n  " + "\n  ".join(str(path) for path in pkgs_candidates) +
    "\nset AGENT0S_PKGS_PATH to the omarchy-pkgs checkout",
    file=sys.stderr,
  )
  sys.exit(1)
settings_pkgbuild_path = pkgs_root / "agent0s-settings/PKGBUILD"
agent0s_pkgbuild_path = pkgs_root / "agent0s/PKGBUILD"
if not settings_pkgbuild_path.exists():
  settings_pkgbuild_path = pkgs_root / "agent0s-settings-dev/PKGBUILD"
if not agent0s_pkgbuild_path.exists():
  agent0s_pkgbuild_path = pkgs_root / "agent0s-dev/PKGBUILD"
pkgbuild = settings_pkgbuild_path.read_text()
agent0s_pkgbuild = agent0s_pkgbuild_path.read_text()
errors = []
package_defaults = [
  ("default/uwsm/env.d/10-agent0s", "/usr/share/uwsm/env.d/10-agent0s", "uwsm/env"),
  ("default/uwsm/default", None, "uwsm/default"),
  ("default/environment.d/10-agent0s-fcitx.conf", "/usr/lib/environment.d/10-agent0s-fcitx.conf", "environment.d/fcitx.conf"),
  ("default/fontconfig/conf.avail/50-agent0s.conf", "/usr/share/fontconfig/conf.avail/50-agent0s.conf", "fontconfig/fonts.conf"),
  ("default/xdg-terminal-exec/hyprland-xdg-terminals.list", "/usr/share/xdg-terminal-exec/hyprland-xdg-terminals.list", "xdg-terminals.list"),
  ("default/applications/mimeapps.list", "/usr/share/applications/mimeapps.list", "mimeapps.list"),
  ("etc/fastfetch/config.jsonc", "/etc/fastfetch/config.jsonc", "fastfetch/config.jsonc"),
  ("default/systemd/user/bt-agent.service", "/usr/lib/systemd/user/bt-agent.service", "systemd/user/bt-agent.service"),
  ("default/systemd/user/agent0s-sleep-lock.service", "/usr/lib/systemd/user/agent0s-sleep-lock.service", "systemd/user/agent0s-sleep-lock.service"),
  ("default/systemd/user/agent0s-recover-internal-monitor.service", "/usr/lib/systemd/user/agent0s-recover-internal-monitor.service", "systemd/user/agent0s-recover-internal-monitor.service"),
  ("default/systemd/user/agent0s-migrate-notify.service", "/usr/lib/systemd/user/agent0s-migrate-notify.service", "systemd/user/agent0s-migrate-notify.service"),
  ("default/systemd/user/agent0s-tailscale-receive.service", "/usr/lib/systemd/user/agent0s-tailscale-receive.service", "systemd/user/agent0s-tailscale-receive.service"),
  ("default/systemd/user/agent0s-fcitx5.service", "/usr/lib/systemd/user/agent0s-fcitx5.service", "systemd/user/agent0s-fcitx5.service"),
  ("default/systemd/user/agent0s-crash-watch.service", "/usr/lib/systemd/user/agent0s-crash-watch.service", "systemd/user/agent0s-crash-watch.service"),
  ("default/systemd/zram-generator.conf.d/90-agent0s.conf", "/usr/lib/systemd/zram-generator.conf.d/90-agent0s.conf", "systemd/zram-generator.conf.d/90-agent0s.conf"),
  ("default/systemd/system/plocate-updatedb.service.d/10-agent0s.conf", "/usr/lib/systemd/system/plocate-updatedb.service.d/10-agent0s.conf", "systemd/system/plocate-updatedb.service.d/10-agent0s.conf"),
  ("default/fonts/agent0s/agent0s.ttf", "/usr/share/fonts/agent0s/agent0s.ttf", "agent0s.ttf"),
  ("default/snapper/root", "/etc/snapper/config-templates/agent0s", "snapper/root"),
]

for source, destination, legacy in package_defaults:
  if not (root / source).exists():
    errors.append(f"missing package default source: {source}")
  if (root / "config" / legacy).exists():
    errors.append(f"legacy path still in config/: {legacy}")
  if destination and (source not in pkgbuild or destination not in pkgbuild):
    errors.append(f"PKGBUILD does not explicitly install {source} -> {destination}")

# Existing users have an absolute wants symlink to the old unit path, and the
# migration that repoints it only runs for users who run an update -- the
# opposite of who the notifier is for. Dropping this alias strands them.
notify_alias = 'ln -sfn agent0s-migrate-notify.service "$pkgdir/usr/lib/systemd/user/agent0s-update-user-notify.service"'
if notify_alias not in pkgbuild:
  errors.append(
    "PKGBUILD does not ship the agent0s-update-user-notify.service compatibility "
    "alias, so users who have not run migration 1785095882 lose the login notifier"
  )

alpm_hooks = [
  "00-agent0s-update-guard.hook",
  "10-agent0s-hyprland-reload-pause.hook",
  "90-agent0s-hyprland-reload-resume.hook",
]
for hook in alpm_hooks:
  source = f"default/libalpm/hooks/{hook}"
  destination = f"/usr/share/libalpm/hooks/{hook}"
  if not (root / source).exists():
    errors.append(f"missing package default source: {source}")
  if source not in agent0s_pkgbuild or destination not in agent0s_pkgbuild:
    errors.append(f"agent0s PKGBUILD does not install {source} -> {destination}")

if errors:
  print("\n".join(errors), file=sys.stderr)
  sys.exit(1)
PY
pass "package-owned defaults live outside config"

grep -F 'dofile((os.getenv("AGENT0S_PATH") or "/usr/share/agent0s") .. "/default/hypr/bootstrap.lua")' "$ROOT/config/hypr/hyprland.lua" >/dev/null
grep -F 'require("default.hypr.agent0s")' "$ROOT/config/hypr/hyprland.lua" >/dev/null
grep -F 'package.path = home' "$ROOT/default/hypr/bootstrap.lua" >/dev/null
grep -F '/.local/state/?.lua;' "$ROOT/default/hypr/bootstrap.lua" >/dev/null
pass "Hyprland user entrypoint keeps package and state path bootstrap in defaults"

AGENT0S_PATH="$ROOT" lua <<'LUA'
package.loaded["default.hypr.agent0s"] = true
package.loaded["default.hypr.require_optional"] = true
package.loaded["hypr.looknfeel"] = true
package.loaded["agent0s.current.theme.hyprland"] = true
package.loaded["unrelated.module"] = true

dofile(os.getenv("AGENT0S_PATH") .. "/default/hypr/bootstrap.lua")

assert(package.loaded["default.hypr.agent0s"] == nil)
assert(package.loaded["default.hypr.require_optional"] == nil)
assert(package.loaded["hypr.looknfeel"] == nil)
assert(package.loaded["agent0s.current.theme.hyprland"] == nil)
assert(package.loaded["unrelated.module"] == true)
LUA
pass "Hyprland bootstrap reloads cached Agent0S config modules"

TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/home/.config/agent0s"

ipc_mock_bin="$TMPDIR/ipc-mock"
mkdir -p "$ipc_mock_bin"
cat >"$ipc_mock_bin/agent0s-shell" <<'SH'
#!/bin/bash
set -euo pipefail

mkdir -p "$HOME/.local/state/agent0s"
printf '%s\n' "$*" >>"$HOME/.local/state/agent0s/shell-ipc-calls"
printf 'ok\n'
SH
chmod +x "$ipc_mock_bin/agent0s-shell"
export PATH="$ipc_mock_bin:$PATH"

cat >"$TMPDIR/home/.config/agent0s/shell.json" <<'JSON'
{
  "version": 1,
  "bar": {
    "layout": {
      "left": [{ "id": "agent0s.menu" }, { "id": "agent0s.workspaces" }, { "id": "agent0s.active-window" }],
      "center": [{ "id": "agent0s.clock" }, { "id": "agent0s.weather" }, { "id": "agent0s.system-update" }, { "id": "agent0s.tailscale" }],
      "right": [{ "id": "agent0s.tray" }, { "id": "agent0s.microphone" }, { "id": "agent0s.bluetooth" }]
    }
  },
  "plugins": []
}
JSON

mkdir -p "$TMPDIR/home/.config/agent0s/plugins/local.demo-bar"
cat >"$TMPDIR/home/.config/agent0s/plugins/local.demo-bar/manifest.json" <<'JSON'
{
  "schemaVersion": 1,
  "id": "local.demo-bar",
  "name": "Demo bar",
  "version": "1.0.0",
  "author": "Test",
  "description": "Replacement bar for config tests",
  "kinds": ["bar"],
  "entryPoints": { "bar": "Bar.qml" }
}
JSON
touch "$TMPDIR/home/.config/agent0s/plugins/local.demo-bar/Bar.qml"

if HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar use local.nonexistent-bar 2>/dev/null; then
  fail "bar use accepted an unknown bar option"
fi
pass "bar use rejects an unknown bar option"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar use local.demo-bar
jq -e '.bar.id == "local.demo-bar"' "$TMPDIR/home/.config/agent0s/shell.json" >/dev/null
pass "shell config selects a bar option"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar reset
jq -e '.bar.id == null' "$TMPDIR/home/.config/agent0s/shell.json" >/dev/null
pass "shell config resets to built-in bar option"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar move agent0s.active-window right
grep -Fqx 'shell moveBarWidget agent0s.active-window {"section":"right"}' \
  "$TMPDIR/home/.local/state/agent0s/shell-ipc-calls"
pass "bar move accepts a positional target section"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar move agent0s.active-window left
grep -Fqx 'shell moveBarWidget agent0s.active-window {"section":"left"}' \
  "$TMPDIR/home/.local/state/agent0s/shell-ipc-calls"
pass "bar move can restore a widget with positional syntax"

if HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar move agent0s.active-window left --section right 2>/dev/null; then
  fail "bar move accepted positional and flagged target sections"
fi
pass "bar move rejects conflicting target section syntax"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar position bottom
jq -e '
  .bar.position == "bottom" and
  .plugins == []
' "$TMPDIR/home/.config/agent0s/shell.json" >/dev/null
pass "shell config sets bar position"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar transparent true
jq -e '
  .bar.transparent == true and
  .bar.position == "bottom" and
  .plugins == []
' "$TMPDIR/home/.config/agent0s/shell.json" >/dev/null
pass "shell config sets bar transparency"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar transparent toggle
jq -e '.bar.transparent == false' "$TMPDIR/home/.config/agent0s/shell.json" >/dev/null
pass "shell config toggles bar transparency"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar set agent0s.bluetooth enabled false --json
grep -Fqx 'shell setBarWidget agent0s.bluetooth enabled false {}' \
  "$TMPDIR/home/.local/state/agent0s/shell-ipc-calls"
pass "bar set accepts false JSON values"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar set agent0s.bluetooth optional null --json
grep -Fqx 'shell setBarWidget agent0s.bluetooth optional null {}' \
  "$TMPDIR/home/.local/state/agent0s/shell-ipc-calls"
pass "bar set accepts null JSON values"

if HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar set agent0s.bluetooth broken '{' --json 2>/dev/null; then
  fail "bar set accepted malformed JSON"
fi
pass "bar set rejects malformed JSON"

if HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" agent0s-bar set agent0s.bluetooth broken 'false null' --json 2>/dev/null; then
  fail "bar set accepted multiple JSON values"
fi
pass "bar set rejects multiple JSON values"

mock_bin="$TMPDIR/mock-bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/agent0s-refresh-config" <<'SH'
#!/bin/bash
set -euo pipefail

relative_path="${1:-}"
[[ -n $relative_path ]] || exit 1
mkdir -p "$HOME/.config/$(dirname "$relative_path")"
cp "$AGENT0S_PATH/config/$relative_path" "$HOME/.config/$relative_path"
SH

cat >"$mock_bin/agent0s-restart-shell" <<'SH'
#!/bin/bash
set -euo pipefail

mkdir -p "$HOME/.local/state/agent0s"
touch "$HOME/.local/state/agent0s/restart-shell-called"
SH

cat >"$mock_bin/agent0s-shell" <<'SH'
#!/bin/bash
[[ ${AGENT0S_TEST_SHELL_DOWN:-0} == "1" ]] && exit 1
printf 'ok\n'
SH

cat >"$mock_bin/agent0s-installed-service-dropbox" <<'SH'
#!/bin/bash
set -euo pipefail

[[ ${AGENT0S_TEST_DROPBOX:-0} == "1" ]]
SH

cat >"$mock_bin/agent0s-installed-service-tailscale" <<'SH'
#!/bin/bash
set -euo pipefail

[[ ${AGENT0S_TEST_TAILSCALE:-0} == "1" ]]
SH

chmod +x "$mock_bin"/*
mock_path="$mock_bin:$ROOT/bin:$PATH"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" PATH="$mock_path" AGENT0S_TEST_DROPBOX=0 AGENT0S_TEST_TAILSCALE=0 agent0s-bar defaults
jq -e --slurpfile defaults "$ROOT/config/agent0s/shell.json" '
  .bar == $defaults[0].bar and
  .plugins == []
' "$TMPDIR/home/.config/agent0s/shell.json" >/dev/null
pass "bar defaults restores the stock bar"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" PATH="$mock_path" AGENT0S_TEST_DROPBOX=1 AGENT0S_TEST_TAILSCALE=1 agent0s-bar defaults
jq -e '
  def ids: map(.id // .);
  (.bar.layout.right | ids) as $right |
  ($right | index("agent0s.tray")) as $tray |
  ($right | index("agent0s.tailscale") == $tray + 1) and
  ($right | index("agent0s.dropbox") == $tray + 2) and
  (.bar.layout.center | ids | index("agent0s.tailscale") == null)
' "$TMPDIR/home/.config/agent0s/shell.json" >/dev/null
pass "bar defaults places plugins for running optional services"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" PATH="$mock_path" \
  AGENT0S_TEST_SHELL_DOWN=1 AGENT0S_TEST_DROPBOX=1 AGENT0S_TEST_TAILSCALE=1 \
  agent0s-bar defaults
jq -e '
  def ids: map(.id // .);
  (.bar.layout.right | ids) as $right |
  ($right | index("agent0s.tray")) as $tray |
  ($right | index("agent0s.tailscale") == $tray + 1) and
  ($right | index("agent0s.dropbox") == $tray + 2) and
  (.bar.layout.center | ids | index("agent0s.tailscale") == null)
' "$TMPDIR/home/.config/agent0s/shell.json" >/dev/null
pass "bar defaults places service widgets without a running shell"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" PATH="$mock_path" AGENT0S_TEST_DROPBOX=0 AGENT0S_TEST_TAILSCALE=0 agent0s-refresh-shell
jq -e '
  def ids: map(.id // .);
  ([.bar.layout.left, .bar.layout.center, .bar.layout.right] | map(ids) | add) as $all |
  ($all | index("agent0s.dropbox") == null) and
  ($all | index("agent0s.tailscale") == null)
' "$TMPDIR/home/.config/agent0s/shell.json" >/dev/null
pass "shell refresh keeps optional service widgets absent when services are unavailable"

HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" PATH="$mock_path" AGENT0S_TEST_DROPBOX=1 AGENT0S_TEST_TAILSCALE=1 agent0s-refresh-shell
jq -e '
  def ids: map(.id // .);
  (.bar.layout.right | ids) as $right |
  ($right | index("agent0s.tray")) as $tray |
  ($right | index("agent0s.tailscale") == $tray + 1) and
  ($right | index("agent0s.dropbox") == $tray + 2) and
  (.bar.layout.center | ids | index("agent0s.tailscale") == null)
' "$TMPDIR/home/.config/agent0s/shell.json" >/dev/null
[[ -f $TMPDIR/home/.local/state/agent0s/restart-shell-called ]] || fail "shell refresh restarts shell"
pass "shell refresh places optional service widgets when services are available"

if grep -RIl 'upgrade-to-quattro\|Agent0S 4\.0 is upgraded' "$ROOT/migrations" >/dev/null; then
  fail "4.0 upgrade is not modeled as a migration"
fi
pass "4.0 upgrade is handled outside the migration runner"
