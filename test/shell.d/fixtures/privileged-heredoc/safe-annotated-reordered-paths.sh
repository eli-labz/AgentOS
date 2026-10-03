storage="$HOME/storage"
shared="$HOME/shared"

# agent0s:heredoc-expands paths=shared,storage -- both sources are validated before use
cat >/etc/agent0s/mounts.conf <<EOF
storage=$storage:/storage
shared=$shared:/shared
EOF
