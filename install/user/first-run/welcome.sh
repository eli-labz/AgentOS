# Real newlines, not a literal \n: the card renders the body as it arrives, and
# elides past three lines.
agent0s-notification-send -u critical -g  "Learn Keybindings" \
  $'Super + K for cheatsheet.\nSuper + Space for Agent0S Menu.' \
  --exec agent0s-menu-keybindings
