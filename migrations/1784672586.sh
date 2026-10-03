echo "Switch to the Agent0S quickshell-git build so shell restarts wait for instance exit"

if ! agent0s-pkg-present quickshell-git; then
  # One transaction with --ask 4 so pacman accepts replacing the conflicting
  # quickshell package in place; packages depending on quickshell stay
  # satisfied through the provides.
  sudo pacman -S --noconfirm --ask 4 quickshell-git
fi
