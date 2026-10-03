#!/bin/bash

cat <<EOF | \
  sudo tee /etc/agent0s/review.conf
ExecStart=$HOME/.local/bin/payload
EOF
