# Set identification from install inputs
if [[ -n ${AGENT0S_USER_NAME//[[:space:]]/} ]]; then
  git config --global user.name "$AGENT0S_USER_NAME"
fi

if [[ -n ${AGENT0S_USER_EMAIL//[[:space:]]/} ]]; then
  git config --global user.email "$AGENT0S_USER_EMAIL"
fi
