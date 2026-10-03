# Install the LV2 plugins that shipped speaker tunings need.
#
# Every tuning ends in a lookahead limiter, which is an LV2 plugin. Without it
# the filter-chain graph fails to instantiate and the tuning sink silently never
# appears, so the package is a hard requirement wherever a tuning applies. It is
# only pulled in on machines that have one.

if agent0s-audio-tuning match >/dev/null; then
  agent0s-pkg-add lsp-plugins-lv2
fi
