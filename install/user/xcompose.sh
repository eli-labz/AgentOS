# Set default XCompose that is triggered with CapsLock
tee ~/.XCompose >/dev/null <<EOF
# Run agent0s-restart-xcompose to apply changes

# Include fast emoji access
include "/usr/share/agent0s/default/xcompose"

# Identification
<Multi_key> <space> <n> : "$AGENT0S_USER_NAME"
<Multi_key> <space> <e> : "$AGENT0S_USER_EMAIL"
EOF
