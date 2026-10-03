sudo dd status=none of=/etc/agent0s/boot.conf <<EOF
cmdline=$boot_params
EOF
