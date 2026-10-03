# agent0s:heredoc-expands paths=none -- the positional argument is a scalar
sudo tee /etc/agent0s/example.conf <<EOF
argument=$1
command=$HOME/.local/share/agent0s/bin/example
EOF
