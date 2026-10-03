echo "Require signed packages from the Agent0S repository"

# The [agent0s] repo predates the Agent0S packaging key, so existing installs
# carry a SigLevel override that also accepts unsigned packages. Packages are
# signed now, so drop the override and let the repo inherit the global
# SigLevel = Required DatabaseOptional like every other repo. Machine-wide and
# self-detecting, so another user's rerun no-ops.
agent0s_sig_override='SigLevel = Optional TrustAll'

if [[ -f /etc/pacman.conf ]] &&
  sed -n '/^\[agent0s\]/,/^\[/p' /etc/pacman.conf | grep -qxF "$agent0s_sig_override"; then
  # Requiring signatures with an untrusted packaging key would fail every
  # agent0s transaction, including the one that could repair it.
  if agent0s-pkg-missing omarchy-keyring ||
    ! sudo pacman-key --list-keys 40DFB630FF42BCFFB047046CF0134EE680CAC571 &>/dev/null; then
    agent0s-update-keyring
  fi

  sudo sed -i "/^\[agent0s\]/,/^\[/{/^$agent0s_sig_override$/d}" /etc/pacman.conf
fi
