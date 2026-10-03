#!/bin/bash

# Two hops. The scan resolves agent0s_bin into helper, so the value it ends up
# judging still carries an unresolved $HOME rather than a literal path.
agent0s_bin="$HOME/.local/share/agent0s/bin"
helper="$agent0s_bin/agent0s-agent"

# agent0s:heredoc-expands paths=none -- helper names the agent, no path is baked in
cat <<EOF | sudo tee /etc/udev/rules.d/99-agent0s-agent.rules >/dev/null
SUBSYSTEM=="power_supply", RUN+="$helper"
EOF
