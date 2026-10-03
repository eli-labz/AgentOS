# Agent0S Shell: Bar, Plugins, and Idle

Read this before changing the status bar, notifications, shell plugins,
widgets, or idle/lock behavior.

The bar, notification daemon, settings panel, and assorted overlays all run
inside a single long-running Quickshell process (`agent0s-shell`).

```
~/.config/agent0s/shell.json             # User overrides: bar, plugins, idle
~/.config/agent0s/plugins/<plugin-id>/   # User-owned shell plugins
$AGENT0S_PATH/config/agent0s/shell.json  # Canonical defaults
```

The shell hot-reloads `shell.json` on save — no restart needed for layout
changes. `idle.screensaver` and `idle.lock` are seconds since user idle began.

**Commands:** `agent0s restart shell`, `agent0s refresh shell`

## Bar Layout

Use the `agent0s bar` group to move and manage widgets:

```bash
agent0s bar move agent0s.clock --section right
```

For layout edits beyond what the commands cover, edit the bar configuration
in `~/.config/agent0s/shell.json`; it hot-reloads on save.

## Customizing Built-In Plugins and Widgets

To customize a built-in bar widget, never edit `$AGENT0S_PATH/shell/plugins/`.
Clone it into the user plugin directory instead:

```bash
agent0s plugin clone agent0s.workspaces
# Edit ~/.config/agent0s/plugins/<username>.workspaces/; saved changes reload automatically.
```

Cloning switches the bar to the cloned copy (e.g. `<username>.workspaces`),
which is yours to edit and survives updates.

Saving a file anywhere under `~/.config/agent0s/plugins/` reloads plugin code
automatically. If a change somehow fails to apply, force a reload with
`agent0s-shell shell rescanPlugins`.

## Idle and Lock

Set `idle.screensaver` and `idle.lock` in `~/.config/agent0s/shell.json`,
in seconds since user idle began. Example: "lock after ten minutes" means
setting `idle.lock` to `600`.
