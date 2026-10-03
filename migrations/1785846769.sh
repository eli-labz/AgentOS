echo "Install default coding agent mise wrappers"

if [[ ! -f $HOME/.local/state/agent0s/preinstalls-removed ]]; then
  agent0s-mise-install github:can1357/oh-my-pi omp
  agent0s-mise-install npm:@xai-official/grok grok
  agent0s-mise-install crush
elif [[ -f $HOME/.local/bin/omp ]] && grep -Eq 'mise use -g .*"oh-my-pi"' "$HOME/.local/bin/omp"; then
  rm -f "$HOME/.local/bin/omp"
fi
