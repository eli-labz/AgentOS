mask=$((1 << bits))

cat >/etc/agent0s/agent.conf <<EOF
helper=$HOME/.local/share/agent0s/bin/agent0s-agent
EOF
