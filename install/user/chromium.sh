# Chromium ships in the base packages, so it never goes through
# agent0s-install-browser, and fresh installs mark every migration as already
# applied. Without this, the bundled extensions load but have no native
# messaging host to talk to.
agent0s-install-chromium-copy-url
agent0s-install-chromium-ytdlp
