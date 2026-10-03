echo "Hand Hermes Desktop the Agent0S theme as a skin"

# Only the app Agent0S installed under Install > AI follows the theme by itself.
# A Hermes the user set up some other way keeps whatever skin they chose.
agent0s-pkg-present hermes-desktop || exit 0

# The same hand-over a fresh install does. A Hermes that is not ready or refuses
# the write is reported and done with there; only Agent0S's own failures return.
agent0s-theme-set-hermes --activate
