tmp=/tmp/agent0s-generated
cat >"$tmp" <<EOF
command=$HOME/.local/share/agent0s/bin/example
EOF
sudo install -m644 "${tmp}" /etc/agent0s/example.conf
