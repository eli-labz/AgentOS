#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

dns="$ROOT/bin/agent0s-dns"
hardware_network="$ROOT/install/hardware/network.sh"

! grep -F 'systemd-networkd' "$dns" >/dev/null || fail "agent0s-dns no longer restarts systemd-networkd"
grep -F 'NetworkManager/conf.d/20-agent0s-dns.conf' "$dns" >/dev/null
grep -F '[global-dns-domain-*]' "$dns" >/dev/null
grep -F 'ipv4.ignore-auto-dns yes' "$dns" >/dev/null
grep -F 'ipv4.ignore-auto-dns no' "$dns" >/dev/null
grep -F 'nmcli device reapply' "$dns" >/dev/null
grep -F 'nmcli general reload conf' "$dns" >/dev/null
grep -F 'nmcli general reload dns-full' "$dns" >/dev/null
if grep -F 'nmcli general reload conf,dns-full' "$dns" >/dev/null; then
  fail "agent0s-dns must not push DNS before reapplying active profiles"
fi
pass "agent0s-dns configures DNS through NetworkManager"

grep -F 'systemd-networkd.service' "$hardware_network" >/dev/null
grep -F 'systemd-networkd.socket' "$hardware_network" >/dev/null
grep -F '20-wlan.network' "$hardware_network" >/dev/null
grep -F 'agent0s-networkd-retired' "$hardware_network" >/dev/null
pass "hardware setup retires archinstall networkd state"
