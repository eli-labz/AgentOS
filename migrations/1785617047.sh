echo "Install oh-my-pi (omp) via mise wrapper"

if [[ ! -f $HOME/.local/state/agent0s/preinstalls-removed ]]; then
  agent0s-mise-install github:can1357/oh-my-pi omp
fi
