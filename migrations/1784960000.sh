echo "Install the speaker tuning for XPS 2026 14/16"

# Speaker tunings are PipeWire filter-chain drop-ins gated on a hardware
# predicate, so this is a no-op on machines without one. The limiter is an LV2
# plugin and the graph will not instantiate without it.

if agent0s-audio-tuning match >/dev/null 2>&1; then
  agent0s-pkg-add lsp-plugins-lv2
  agent0s-audio-tuning on
fi
