tmp=$(mktemp)

cat >"$tmp" <<EOF
#!/bin/bash
exec "$HOME/.local/share/agent0s/bin/agent0s-agent" "$@"
EOF

sudo install -m 0755 "$tmp" /usr/local/bin/agent0s-agent-shim
