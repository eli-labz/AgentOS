echo "Rename the model usage widget to agents and prime its data files"

# The widget formerly known as agent0s.model-usage is now agent0s.agents, and
# it no longer scans providers itself: it displays the records that
# agent0s-agent-usage-update writes under ~/.local/state/agent0s/agents/usage/.
# Rename the widget wherever a user's config mentions it — bar layout entries
# keep their settings, a disabled widget stays disabled — then generate the
# records once so the bar doesn't sit empty until the widget's first refresh
# timer, and drop the old scanner's cache directory, which nothing reads
# anymore.

config_file="$HOME/.config/agent0s/shell.json"

if [[ -s $config_file ]]; then
  tmp=$(mktemp)
  jq '
    def rename:
      if . == "agent0s.model-usage" then
        "agent0s.agents"
      elif type == "object" and .id == "agent0s.model-usage" then
        .id = "agent0s.agents"
      else
        .
      end;

    (if (.bar.layout? | type) == "object" then
      .bar.layout |= map_values(if type == "array" then map(rename) else . end)
    else . end)
    | (if (.disabledPlugins? | type) == "array" then
      .disabledPlugins |= map(rename)
    else . end)
  ' "$config_file" >"$tmp" && mv "$tmp" "$config_file" || rm -f "$tmp"
fi

rm -rf "$HOME/.cache/agent0s/model-usage"

agent0s-agent-usage-update || true
