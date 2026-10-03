run_logged "$AGENT0S_INSTALL/user/theme.sh"
run_logged "$AGENT0S_INSTALL/user/chromium.sh"
run_logged "$AGENT0S_INSTALL/user/git.sh"
run_logged "$AGENT0S_INSTALL/user/xcompose.sh"
run_logged "$AGENT0S_INSTALL/user/mise-work.sh"

run_logged "$AGENT0S_INSTALL/user/hardware/asus/fix-audio-mixer.sh"
run_logged "$AGENT0S_INSTALL/user/hardware/asus/fix-mic.sh"
run_logged "$AGENT0S_INSTALL/user/hardware/framework/fix-f13-amd-audio-input.sh"
run_logged "$AGENT0S_INSTALL/user/hardware/dell/xps13-text-scaling.sh"
run_logged "$AGENT0S_INSTALL/user/hardware/fix-nouveau-cursor.sh"

run_logged "$AGENT0S_INSTALL/user/default-keyring.sh"
run_logged "$AGENT0S_INSTALL/user/mise.sh"
