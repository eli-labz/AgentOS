echo "Install hey (hey-cli) via mise wrapper"

if [[ ! -f $HOME/.local/state/agent0s/preinstalls-removed ]]; then
  agent0s-mise-install github:basecamp/hey-cli hey
fi
