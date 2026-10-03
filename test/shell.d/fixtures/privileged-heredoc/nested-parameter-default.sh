#!/bin/bash

# agent0s:heredoc-expands paths=none -- review regression fixture
sudo tee /etc/agent0s/review.conf >/dev/null <<EOF
ExecStart=${target:-$HOME/.local/bin/payload}
EOF
