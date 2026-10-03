echo "Install basecamp (basecamp-cli) via mise wrapper"

if [[ ! -f $HOME/.local/state/agent0s/preinstalls-removed ]]; then
  agent0s-mise-install github:basecamp/basecamp-cli basecamp
fi
