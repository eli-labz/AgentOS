echo "Enable Dell XPS 13 sidecar speaker amplifiers"

if agent0s-hw-dell-xps13-sidecar-amps; then
  source "$AGENT0S_PATH/install/hardware/dell-xps13-sidecar-amps.sh"
  agent0s-state set reboot-required
fi
