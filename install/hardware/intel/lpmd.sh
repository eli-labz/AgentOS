# Install Intel Low Power Mode Daemon for supported hybrid Intel CPUs (Alder Lake and newer)
# Supported models: Alder Lake (151/154), Raptor Lake (183/186/191),
# Meteor Lake (170/172), Lunar Lake (189), Panther Lake (204)

if agent0s-hw-intel && agent0s-battery-present; then
  cpu_model=$(grep -m1 "^model\s*:" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | tr -d ' ')
  if [[ "$cpu_model" =~ ^(151|154|170|172|183|186|189|191|204)$ ]]; then
    agent0s-pkg-add intel-lpmd
    sudo systemctl enable intel_lpmd.service
  fi
fi
