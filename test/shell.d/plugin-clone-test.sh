#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
mkdir -p "$TMPDIR/home/.config/agent0s" "$TMPDIR/bin"
CALLS="$TMPDIR/calls"

cat >"$TMPDIR/bin/agent0s-shell" <<'SH'
#!/bin/bash
if [[ $* == *"listShellConfig"* ]]; then
  if [[ -n ${FAKE_SHELL_CONFIG:-} ]]; then
    printf '%s\n' "$FAKE_SHELL_CONFIG"
  else
    printf '{}\n'
  fi
elif [[ $* == *"listPlugins"* ]]; then
  if [[ ${FAKE_NO_DISCOVERY:-0} == 1 ]]; then
    printf '[]\n'
  else
    find "$HOME/.config/agent0s/plugins" -mindepth 2 -maxdepth 2 -name manifest.json -print0 |
      xargs -0 -r jq -s 'map({id: .id, enabled: true})'
  fi
elif [[ $* == *"setPluginEnabled"* ]]; then
  printf 'agent0s-shell %s\n' "$*" >>"$FAKE_CALLS"
  printf 'ok\n'
fi
exit 0
SH

for command in agent0s-plugin-enable agent0s-notification-send fake-editor; do
  cat >"$TMPDIR/bin/$command" <<'SH'
#!/bin/bash
printf '%s %s\n' "${0##*/}" "$*" >>"$FAKE_CALLS"
SH
done
chmod +x "$TMPDIR/bin/"*

clone_plugin() {
  local default_config='{
    "bar": {
      "layout": {
        "left": [{"id": "agent0s.menu"}],
        "center": [{"id": "agent0s.clock", "format": "HH:mm"}],
        "right": []
      }
    }
  }'
  HOME="$TMPDIR/home" USER=tester AGENT0S_PATH="$ROOT" PATH="$TMPDIR/bin:$ROOT/bin:$PATH" \
    FAKE_CALLS="$CALLS" AGENT0S_TEST_ROOT="$ROOT" \
    FAKE_SHELL_CONFIG="${FAKE_CLONE_CONFIG:-$default_config}" \
    agent0s-plugin-clone "$@"
}

clone_plugin agent0s.clock >/dev/null
clock="$TMPDIR/home/.config/agent0s/plugins/tester.clock"

for file in manifest.json BarWidget.qml Panel.qml Model.js; do
  [[ -f $clock/$file ]] || fail "clock clone is missing $file"
done
pass "clone copies the complete plugin"

grep -q 'import "Model.js"' "$clock/BarWidget.qml" &&
  grep -q 'Qt.resolvedUrl("Panel.qml")' "$clock/BarWidget.qml" ||
  fail "clock clone does not preserve local dependencies"
pass "clone keeps plugin dependencies local"

rg -qF "agent0s.clock" "$clock" -g '*.qml' -g '*.js' ||
  fail "clock clone does not preserve the stable runtime id"
pass "clone preserves the built-in runtime IPC id"

jq -e '
  .id == "tester.clock" and
  .name == "My Clock" and
  .barWidget.displayName == "My Clock" and
  .agent0s.clonedFrom == "agent0s.clock" and
  .kinds == ["bar-widget"] and
  .entryPoints.barWidget == "BarWidget.qml"
' "$clock/manifest.json" >/dev/null || fail "clock clone manifest is incorrect"
pass "clone updates identity without replacing the manifest"

grep -qx 'agent0s-plugin-enable tester.clock' "$CALLS" ||
  fail "clone does not enable the editable copy"
grep -qx 'agent0s-notification-send -g 󰐱 Editing Cloned Plugin Original plugin has been replace by clone.' "$CALLS" ||
  fail "clone does not notify that the editable clone is active"
pass "clone enables bar widgets and confirms the editable clone"

clone_plugin agent0s.keyboard-layout >/dev/null
grep -qx 'agent0s-plugin-enable tester.keyboard-layout' "$CALLS" ||
  fail "clone does not enable a clone of a legacy string-form bar entry"
pass "clone enables clones of legacy string-form bar entries"

clone_plugin agent0s.menu >/dev/null
menu="$TMPDIR/home/.config/agent0s/plugins/tester.menu"

for file in manifest.json Menu.qml MenuModel.js BarWidget.qml; do
  [[ -f $menu/$file ]] || fail "menu clone is missing $file"
done
jq -e '
  .id == "tester.menu" and
  .kinds == ["menu", "bar-widget"] and
  .entryPoints.menu == "Menu.qml" and
  .entryPoints.barWidget == "BarWidget.qml"
' "$menu/manifest.json" >/dev/null || fail "menu clone loses plugin kinds"
grep -qx 'agent0s-plugin-enable tester.menu' "$CALLS" ||
  fail "clone does not enable a multi-kind plugin"
pass "clone preserves and enables multi-kind plugins"

remove_output=$(HOME="$TMPDIR/home" AGENT0S_PATH="$ROOT" PATH="$TMPDIR/bin:$ROOT/bin:$PATH" \
  FAKE_CALLS="$CALLS" AGENT0S_TEST_ROOT="$ROOT" \
  agent0s-plugin-remove tester.menu --yes)
grep -qx 'agent0s-shell shell setPluginEnabled tester.menu false' "$CALLS" ||
  fail "removing an enabled clone does not disable it first"
grep -q 'Restored agent0s.menu.' <<<"$remove_output" ||
  fail "removing a clone does not report its restored source"
pass "removing an enabled clone goes through plugin disable and reports its source"

clone_plugin agent0s.active-window >/dev/null
[[ -f $TMPDIR/home/.config/agent0s/plugins/tester.active-window/ActiveWindow.qml ]] ||
  fail "flat bar plugin clone is incomplete"
pass "flat bar plugins clone from adjacent manifests"

grep -qx 'agent0s-plugin-enable tester.active-window' "$CALLS" ||
  fail "clone does not activate a bar widget whose source is absent"
pass "clone activates an absent bar widget"

clone_plugin agent0s.indicators >/dev/null
indicators="$TMPDIR/home/.config/agent0s/plugins/tester.indicators"
for file in Indicators.qml indicators/Dnd.qml indicators/Reminder.qml; do
  [[ -f $indicators/$file ]] || fail "indicators clone is missing $file"
done
grep -q 'Qt.resolvedUrl("indicators/"' "$indicators/Indicators.qml" ||
  fail "indicators clone does not point at its copied components"
pass "flat bar plugins declare extra clone dependencies"

clone_plugin agent0s.tray >/dev/null
[[ -f $TMPDIR/home/.config/agent0s/plugins/tester.tray/TrayModel.js ]] ||
  fail "tray clone is missing its model"
pass "flat bar plugins keep local script dependencies"

clone_plugin agent0s.bar >/dev/null
grep -qx 'agent0s-plugin-enable tester.bar' "$CALLS" ||
  fail "clone does not select a cloned bar"
pass "clone switches full bars"

clone_plugin agent0s.background >/dev/null
grep -qx 'agent0s-plugin-enable tester.background' "$CALLS" ||
  fail "clone does not enable an ordinary cloned plugin"
pass "clone switches ordinary plugins"

EDITOR=fake-editor clone_plugin agent0s.weather --edit >/dev/null
grep -qx "fake-editor $TMPDIR/home/.config/agent0s/plugins/tester.weather" "$CALLS" ||
  fail "clone --edit does not open the clone in EDITOR"
pass "clone --edit opens the clone in EDITOR"
rm -rf "$TMPDIR/home/.config/agent0s/plugins/tester.weather"

mkdir -p "$TMPDIR/home/.config/agent0s/plugins/acme.example"
cat >"$TMPDIR/home/.config/agent0s/plugins/acme.example/manifest.json" <<'JSON'
{"id":"acme.example","name":"Example","kinds":["bar-widget"],"entryPoints":{"barWidget":"Widget.qml"}}
JSON
if clone_plugin acme.example >/dev/null 2>&1; then
  fail "clone accepts a user plugin"
fi
pass "clone is limited to built-in plugins"

if clone_plugin agent0s.weather custom.weather >/dev/null 2>&1; then
  fail "clone accepts a custom id"
fi
[[ ! -e $TMPDIR/home/.config/agent0s/plugins/tester.weather ]] ||
  fail "rejected custom id leaves a clone behind"
pass "clone derives the personal id from the username"

if clone_plugin agent0s.weather --replace >/dev/null 2>&1; then
  fail "clone still accepts bar layout actions"
fi
[[ ! -e $TMPDIR/home/.config/agent0s/plugins/tester.weather ]] ||
  fail "rejected bar action leaves a clone behind"
pass "clone does not accept manual switch options"

if clone_plugin >/dev/null 2>&1; then
  fail "clone opens an interactive picker without a source id"
fi
pass "clone requires an explicit source id"

if FAKE_NO_DISCOVERY=1 clone_plugin agent0s.osd >/dev/null 2>&1; then
  fail "clone succeeds before the shell discovers it"
fi
[[ ! -e $TMPDIR/home/.config/agent0s/plugins/tester.osd ]] ||
  fail "failed clone discovery leaves a partial clone behind"
pass "clone removes a partial clone when switching fails"
