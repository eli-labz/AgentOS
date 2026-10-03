# `>|` is a plain redirect with noclobber overridden, not a redirect into a pipe.
cat >|/etc/agent0s/agent.conf <<EOF
helper=$HOME/.local/share/agent0s/bin/agent0s-agent
EOF
