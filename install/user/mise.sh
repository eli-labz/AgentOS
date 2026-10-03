# Upgrades must not delete the version a running process is executing from:
# mise up would prune the old install dir out from under a live session.
mise settings set upgrade.auto_prune false

agent0s-mise-install codex
agent0s-mise-install claude
agent0s-mise-install crush
agent0s-mise-install antigravity-cli agy
agent0s-mise-install gh
agent0s-mise-install copilot
agent0s-mise-install opencode
agent0s-mise-install npm:playwright playwright
agent0s-mise-install pi
agent0s-mise-install github:can1357/oh-my-pi omp
agent0s-mise-install npm:@xai-official/grok grok
# Cursor's own installer links the same path, so a re-provision keeps it.
agent0s-cmd-missing cursor-agent && agent0s-mise-install cursor-agent
agent0s-mise-install npm:@kitlangton/ghui ghui
agent0s-mise-install aqua:modem-dev/hunk hunk
agent0s-mise-install github:basecamp/hey-cli hey
agent0s-mise-install github:basecamp/basecamp-cli basecamp
agent0s-mise-install npm:cf cf
agent0s-mise-install github:OpenRouterLabs/ori-releases ori
# Every line above writes a stub and cannot fail. This one can: it exits
# non-zero when Hermes Desktop owns Hermes but has not finished setting it up,
# and this leaf is sourced under `bash -eE`, so that would abort the rest of
# agent0s-provision-user -- the default browser, the mailto handler and the
# finalize-user marker all come after it.
agent0s-install-hermes-cli || true
if agent0s-cmd-missing muse; then
  agent0s-mise-install "http:muse[url=https://api.meta.ai/muse-launcher.sh,bin=muse,version_list_url=https://api.meta.ai/muse-code/channels/muse-stable,version_json_path=.version]" muse
fi
