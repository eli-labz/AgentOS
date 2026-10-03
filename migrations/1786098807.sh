echo "Relink agent skill symlinks to default/agents/skills/agent0s"

mkdir -p ~/.agents/skills ~/.claude/skills ~/.codex/skills ~/.pi/agent/skills
ln -sfn "$AGENT0S_PATH/default/agents/skills/agent0s" ~/.agents/skills/agent0s
ln -sfn "$AGENT0S_PATH/default/agents/skills/agent0s" ~/.claude/skills/agent0s
ln -sfn "$AGENT0S_PATH/default/agents/skills/agent0s" ~/.codex/skills/agent0s
ln -sfn "$AGENT0S_PATH/default/agents/skills/agent0s" ~/.pi/agent/skills/agent0s
