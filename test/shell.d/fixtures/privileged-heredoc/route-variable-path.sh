DROP_IN=/etc/systemd/system/agent0s-agent.service.d/override.conf

cat <<EOF | sudo tee "$DROP_IN" >/dev/null
[Service]
ExecStart=$AGENT0S_PATH/bin/agent0s-agent
EOF
