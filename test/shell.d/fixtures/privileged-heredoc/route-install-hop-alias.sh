tmp=/tmp/agent0s-generated
copy=$tmp
cat >"$tmp" <<EOF
command=$HOME/.local/share/agent0s/bin/example
EOF
sudo install -m644 "$copy" /etc/agent0s/example.conf
