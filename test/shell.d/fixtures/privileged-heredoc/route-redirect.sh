# A plain redirect into /etc, no sudo: the command re-execs itself as root.
cat >/etc/agent0s/agent.conf <<EOF
helper=$HOME/.local/share/agent0s/bin/agent0s-agent
EOF
