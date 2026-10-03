mkdir -p ~/.config/agent0s

cat >~/.config/agent0s/agent.conf <<EOF
helper=$HOME/.local/share/agent0s/bin/agent0s-agent
EOF

cat >"$HOME/.local/bin/agent0s-shim" <<EOF
exec "$AGENT0S_PATH/bin/agent0s-agent" "$@"
EOF
