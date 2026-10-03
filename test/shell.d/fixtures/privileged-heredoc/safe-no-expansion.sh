cat <<EOF | sudo tee /etc/udev/rules.d/99-agent0s.rules >/dev/null
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="/usr/bin/agent0s-powerprofiles-set"
EOF
