# Install Panther Lake kernel for Dell XPS Panther Lake systems
# The Agent0S PTL kernel includes Panther Lake display and memory fixes.

if agent0s-hw-match "XPS" && agent0s-hw-intel-ptl; then
  echo "Detected Dell XPS Panther Lake, installing PTL kernel..."

  # linux-ptl required SOF firmware; the new kernel only lists it as optional.
  agent0s-pkg-add linux-omarchy-ptl-novrr-mm linux-omarchy-ptl-novrr-mm-headers sof-firmware
  pacman -Rdd --noconfirm linux linux-headers || true

  # The PTL kernel doesn't provide=linux, so anything depending on linux drags the
  # stock kernel back in and the boot menu grows a second, slower entry.
  if pacman -Qq linux &>/dev/null; then
    echo "WARNING: stock linux kernel still installed alongside the Agent0S PTL kernel:"
    pacman -Qi linux | grep -i "required by"
  fi

  mkdir -p /etc/limine-entry-tool.d
  # Named to sort after agent0s-defaults.conf: drop-ins are read in order and
  # the last BOOT_ORDER wins, so an earlier-sorting name is a silent no-op.
  rm -f /etc/limine-entry-tool.d/dell-xps-panther-lake.conf
  cat > /etc/limine-entry-tool.d/zz-dell-xps-panther-lake.conf <<'EOF'
# Prefer Agent0S kernels while keeping other kernels available for recovery
BOOT_ORDER="linux-omarchy-*, *, *fallback, Snapshots"
EOF
fi
