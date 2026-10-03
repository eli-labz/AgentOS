#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

WEATHER_FILE="$HOME/.local/state/agent0s/settings/weather.json"
weather_backup=$(mktemp)
weather_existed=0

if [[ -f $WEATHER_FILE ]]; then
  cp "$WEATHER_FILE" "$weather_backup"
  weather_existed=1
fi

hide_panels() {
  local plugin

  for plugin in agent0s.weather agent0s.bluetooth agent0s.network agent0s.audio agent0s.monitor agent0s.power; do
    agent0s-shell shell hide "$plugin" >/dev/null 2>&1 || true
  done
}

restore_weather() {
  hide_panels

  if ((weather_existed)); then
    mkdir -p "$(dirname "$WEATHER_FILE")"
    cp "$weather_backup" "$WEATHER_FILE"
  else
    rm -f "$WEATHER_FILE"
  fi

  rm -f "$weather_backup"
}

trap restore_weather EXIT

open_and_capture_panel() {
  local name="$1" plugin="$2"

  agent0s-shell shell summon "$plugin" >/dev/null
  wait_until "$name panel opens" 15 layer_present "agent0s-keyboard-panel"
  sleep 1
  screenshot "success-panel-$name"

  agent0s-shell shell hide "$plugin" >/dev/null
  wait_until "$name panel closes" 15 layer_absent "agent0s-keyboard-panel"
}

# Give weather deterministic coordinates so this test exercises the real
# Open-Meteo forecast instead of IP geolocation through wttr.in.
agent0s-weather-location --set "San Francisco" "37.7749,-122.4194"
agent0s-shell shell summon agent0s.weather >/dev/null
wait_until "weather panel opens" 15 layer_present "agent0s-keyboard-panel"
wait_until "weather location is visible" 30 screen_contains "SAN FRANCISCO"
wait_until "weather details are visible" 30 screen_contains "WIND"
screenshot "success-panel-weather"
agent0s-shell shell hide agent0s.weather >/dev/null
wait_until "weather panel closes" 15 layer_absent "agent0s-keyboard-panel"

status=0
panels='bluetooth|agent0s.bluetooth
network|agent0s.network
audio|agent0s.audio
monitor|agent0s.monitor'

while IFS='|' read -r name plugin; do
  if ! (trap - EXIT; open_and_capture_panel "$name" "$plugin"); then
    status=1
    hide_panels
    wait_until "$name failed panel is dismissed" 15 layer_absent "agent0s-keyboard-panel"
  fi
done <<<"$panels"

# The power widget intentionally disappears on desktops and VMs without a
# battery. Exercise it on laptops, and verify that hardware-less sessions take
# the supported no-panel path instead of treating that as a shell failure.
if upower -e | grep '/battery_' >/dev/null; then
  if ! (trap - EXIT; open_and_capture_panel "power" "agent0s.power"); then
    status=1
    hide_panels
    wait_until "power failed panel is dismissed" 15 layer_absent "agent0s-keyboard-panel"
  fi
else
  pass "power panel is hidden without battery hardware"
  screenshot "success-panel-power-unavailable"
fi

# The common panel keyboard contract uses Tab to move to the next bar panel.
agent0s-shell shell summon agent0s.bluetooth >/dev/null
wait_until "panel keyboard navigation starts on bluetooth" 15 screen_contains "Bluetooth"
screenshot "success-panel-navigation-01-bluetooth"
wtype -k Tab
sleep 2
wait_until "Tab keeps a shell panel open" 15 layer_present "agent0s-keyboard-panel"
screenshot "success-panel-navigation-02-next"
hide_panels
wait_until "keyboard-navigated panel closes" 15 layer_absent "agent0s-keyboard-panel"

# Reopening during the fade keeps the layer surface mapped. Verify the focus
# prime reacquires compositor keyboard focus instead of relying on map-time
# OnDemand behavior, which would leave Escape in the previously focused app.
agent0s-shell shell summon agent0s.bluetooth >/dev/null
wait_until "focus-prime panel opens" 15 layer_present "agent0s-keyboard-panel"
if (( $(hyprctl -j monitors | jq length) == 1 )); then
  layer_absent "agent0s-keyboard-panel-dismiss" || fail "single-monitor panel has no dismissal twin"
  pass "single-monitor panel has no dismissal twin"
fi
agent0s-shell shell hide agent0s.bluetooth >/dev/null
agent0s-shell shell summon agent0s.bluetooth >/dev/null
wait_until "focus-prime panel reopens" 15 layer_present "agent0s-keyboard-panel"
sleep 1
screenshot "success-panel-focus-prime-reopened"
wtype -k Escape
wait_until "Escape closes a panel reopened during fade" 15 layer_absent "agent0s-keyboard-panel"

trap - EXIT
restore_weather
exit $status
