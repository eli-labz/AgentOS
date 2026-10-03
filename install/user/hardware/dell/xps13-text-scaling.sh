# Nudge text down slightly on the Dell XPS 13 (DX13260, 2026), whose 2560x1600
# panel renders the default size a touch large. Uses the unified display text
# size (shell + GTK + terminals together) rather than GTK scaling alone.
if agent0s-hw-match "DX13260"; then
  agent0s-display-text-size 11
fi
