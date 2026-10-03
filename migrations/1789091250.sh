echo "Activate the Agent0S theme for existing T3 Code installs"

agent0s-pkg-present t3code-bin || exit 0
agent0s-install-ai-t3-code
