echo "Install ori (OpenRouter's agent harness) via mise wrapper"

if [[ ! -f $HOME/.local/state/agent0s/preinstalls-removed ]]; then
  agent0s-mise-install github:OpenRouterLabs/ori-releases ori
fi
