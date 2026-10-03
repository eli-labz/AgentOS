# Setup user theme folder and seed the default only when no theme exists yet.
mkdir -p ~/.config/agent0s/themes

if [[ ! -s $HOME/.local/state/agent0s/current/theme.name ]]; then
  # iso-chroot and provision-owner both run without a live session to notify.
  if [[ ${AGENT0S_SETUP_CONTEXT:-runtime} != "runtime" ]]; then
    AGENT0S_THEME_HEADLESS=1 agent0s-theme-set "Tokyo Night"
    rm -f ~/.config/chromium/SingletonLock # otherwise archiso owns the Chromium singleton
  else
    agent0s-theme-set "Tokyo Night"
  fi
fi
agent0s-theme-set-pi --activate

mkdir -p ~/.config/btop/themes
ln -snf "$HOME/.local/state/agent0s/current/theme/btop.theme" ~/.config/btop/themes/current.theme
