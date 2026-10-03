if lspci | grep -qi 'nvidia'; then
  # Check which kernel is installed and set appropriate headers package
  KERNEL_PACKAGE=$(pacman -Qqs '^linux(-zen|-lts|-hardened|-t2|-ptl|-agent0s-ptl-novrr-mm)?$' | head -1 || true)
  [[ -n $KERNEL_PACKAGE ]] && agent0s-pkg-add "$KERNEL_PACKAGE-headers"

  if agent0s-hw-nvidia-gsp; then
    PACKAGES=(nvidia-open-dkms nvidia-utils lib32-nvidia-utils libva-nvidia-driver)
  elif agent0s-hw-nvidia-without-gsp; then
    PACKAGES=(nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils)
  fi

  # Bail if no supported GPU
  if [[ -z ${PACKAGES+x} ]]; then
    echo "No compatible driver for your NVIDIA GPU. See: https://wiki.archlinux.org/title/NVIDIA"
    exit 0
  fi

  agent0s-pkg-add "${PACKAGES[@]}"

  # Per-session Hyprland NVIDIA env vars are handled by default/hypr/nvidia.lua.

  # Configure modprobe for early KMS
  mkdir -p /etc/modprobe.d
  cat > /etc/modprobe.d/nvidia.conf <<'EOF'
options nvidia_drm modeset=1
EOF

  # Configure mkinitcpio for early loading
  mkdir -p /etc/mkinitcpio.conf.d
  cat > /etc/mkinitcpio.conf.d/nvidia.conf <<'EOF'
MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
EOF
fi
