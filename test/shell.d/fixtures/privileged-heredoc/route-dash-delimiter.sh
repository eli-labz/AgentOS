if true; then
  cat <<-EOF | sudo tee /etc/agent0s/indented.conf >/dev/null
	helper=$HOME/.local/share/agent0s/bin/agent0s-agent
	EOF
fi
