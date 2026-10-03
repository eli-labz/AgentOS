cat <<'EOF' | sudo tee /etc/udev/rules.d/99-agent0s.rules >/dev/null
SUBSYSTEM=="power_supply", RUN+="/usr/bin/agent0s-powerprofiles-set $HOME"
EOF

cat <<"XML" | sudo tee /etc/agent0s/agent.xml >/dev/null
<config path="$HOME/.local/share/agent0s" />
XML
