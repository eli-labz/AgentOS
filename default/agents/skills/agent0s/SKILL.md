---
name: agent0s
description: >
  REQUIRED for end-user customization of Linux desktop, window manager, or system config.
  Use when editing ~/.config/hypr/, ~/.config/agent0s/,
  ~/.config/alacritty/, ~/.config/foot/, ~/.config/kitty/, or ~/.config/ghostty/.
  Triggers: Hyprland, window rules, animations, keybindings, monitors, gaps, borders,
  blur, opacity, agent0s-shell, bar, terminal config, themes, background,
  night light, idle, lock screen, screenshots, reminders, layer rules, workspace
  settings, display config, and user-facing agent0s commands. Excludes Agent0S
  source development through `agent0s dev link` workflows.
---

# Agent0S Skill

Manage [Agent0S](https://omarchy.org/) Linux systems - a beautiful, fun, agentic Arch Linux distribution with Hyprland.

This skill is for end-user customization on installed systems.
It is not for contributing to Agent0S source code.

## When This Skill MUST Be Used

**ALWAYS invoke this skill for end-user requests involving ANY of these:**

- Editing ANY file in `~/.config/hypr/` (window rules, animations, keybindings, monitors, etc.)
- Editing `~/.config/agent0s/shell.json` (status bar layout, widgets)
- Editing terminal configs (alacritty, foot, kitty, ghostty)
- Editing ANY file in `~/.config/agent0s/`
- Window behavior, animations, opacity, blur, gaps, borders
- Layer rules, workspace settings, display/monitor configuration
- Themes, backgrounds, fonts, appearance changes
- User-facing `agent0s` commands (`agent0s theme ...`, `agent0s refresh ...`, `agent0s restart ...`, etc.)
- Screenshots, screen recording, reminders, night light, idle behavior, lock screen

**If you're about to edit a config file in ~/.config/ on this system, STOP and use this skill first.**

**Do NOT use this skill for Agent0S development tasks** (editing the Agent0S source tree, creating migrations, or running `agent0s dev ...` workflows).

## Topic Guides

Deeper instructions for common areas live next to this file. Read the
matching guide before starting:

- [`hyprland.md`](hyprland.md) - keybindings, monitors, window rules, and other Hyprland config
- [`plugins.md`](plugins.md) - the Agent0S shell: bar layout, widgets, plugins, idle behavior
- [`theming.md`](theming.md) - themes, backgrounds, and fonts
- [`hooks.md`](hooks.md) - automation hooks that run on system events
- [`capture.md`](capture.md) - screenshots, screen recordings, OCR text capture, and file sharing
- [`contributing.md`](contributing.md) - reporting Agent0S bugs and submitting fixes upstream

## Critical Safety Rules

For privileged commands, follow the Privilege Escalation rules below: `sudo` when a terminal is available for the password prompt, `pkexec` when it is not. Do not wrap commands that already manage privilege elevation themselves.

**For end-user customization tasks, NEVER modify anything in `/usr/share/agent0s/`** - but READING is safe and encouraged.

This directory is owned by the agent0s package. Any local changes will be
overwritten on the next `agent0s update`.

```
/usr/share/agent0s/     # READ-ONLY - NEVER EDIT (reading is OK)
├── bin/                    # Command source (packaged binaries are on PATH)
├── config/                 # Default config templates
├── themes/                 # Stock themes
├── default/                # System defaults
├── shell/                  # Agent0S shell source and defaults
├── migrations/             # Update migrations
└── install/                # Installation scripts
```

**Reading `/usr/share/agent0s/` is SAFE and useful** - do it freely to:
- Understand how agent0s commands work: `agent0s theme set --help` or `cat $(which agent0s-theme-set)`
- See default configs before customizing: `cat "$AGENT0S_PATH/config/agent0s/shell.json"`
- Check stock theme files to copy for customization
- Reference default hyprland settings: `cat /usr/share/agent0s/default/hypr/*`

**Always use these safe locations instead:**
- `~/.config/` - User configuration (safe to edit)
- `~/.config/agent0s/themes/<custom-name>/` - Custom themes
- `~/.config/agent0s/hooks/` - Custom automation hooks

If the request is to develop Agent0S itself, this skill is out of scope. Follow repository development instructions instead of this skill.

## Privilege Escalation

For an interactive script or command run in a visible terminal, use `sudo` for
privileged work. Agent0S may grant passwordless `sudo` access to particular
commands, and the terminal is the appropriate place to request a password
when one is needed.

Use `pkexec` only when the caller cannot interact with a terminal or cannot
enter a password there, such as a command launched by an agent or a graphical
background process. Do not replace `sudo` with `pkexec` merely because a
command changes system state.

## System Architecture

Agent0S is built on:

| Component | Purpose | Config Location |
|-----------|---------|-----------------|
| **Arch Linux** | Base OS | `/etc/`, `~/.config/` |
| **Hyprland** | Wayland compositor/WM | `~/.config/hypr/` |
| **Agent0S shell** | Status bar + notifications (Quickshell) | `~/.config/agent0s/shell.json` |
| **Launcher/menus** | Quickshell menu | `~/.config/agent0s/extensions/agent0s-menu.jsonc` |
| **Alacritty/Foot/Kitty/Ghostty** | Terminals | `~/.config/<terminal>/` |
| **Agent0S OSD** | On-screen display | Quickshell plugin |

## Command Discovery

Agent0S ships a single `agent0s` CLI that dispatches to all `agent0s-*` binaries via `agent0s <group> <action>`. Always prefer this form — it is self-documenting and stable. The underlying `agent0s-*` binaries still exist on `PATH` and remain safe to read for source.

```bash
# List every documented command and its summary (--all includes hidden commands)
agent0s commands

# Show the commands inside a group
agent0s theme --help
agent0s refresh --help
agent0s restart --help

# Show help for a specific command (does not execute it)
agent0s theme set --help

# Machine-readable listing (binary, route, summary, args, aliases)
agent0s commands --json

# Read a command's source to understand it
cat $(which agent0s-theme-set)
```

### Command Groups

Run `agent0s --help` for the full list. The most common groups:

| Group | Purpose | Example |
|-------|---------|---------|
| `agent0s refresh` | Reset config to defaults (backs up first) | `agent0s refresh shell` |
| `agent0s restart` | Restart a service/app | `agent0s restart shell` |
| `agent0s toggle` | Toggle feature on/off | `agent0s toggle nightlight` |
| `agent0s theme` | Theme management | `agent0s theme set <name>` |
| `agent0s bar` | Bar layout and widgets | `agent0s bar move agent0s.clock --section right` |
| `agent0s plugin` | Manage/clone shell plugins | `agent0s plugin clone agent0s.clock` |
| `agent0s hook` | Install automation hooks | `agent0s hook install theme-set <script>` |
| `agent0s install` | Install optional software / packages | `agent0s install docker dbs` |
| `agent0s launch` | Launch apps | `agent0s launch browser` |
| `agent0s capture` | Screenshots and recordings | `agent0s capture screenshot` |
| `agent0s reminder` | Desktop notification reminders | `agent0s reminder 15 "Pickup Jack"` |
| `agent0s pkg` | Package management | `agent0s pkg add <pkg>` |
| `agent0s setup` | Interactive setup wizards | `agent0s setup security fingerprint` |
| `agent0s update` | System updates | `agent0s update` |

## Configuration Locations

Hyprland config lives in `~/.config/hypr/` — see [`hyprland.md`](hyprland.md).
The Agent0S shell (bar, notifications, plugins, idle) is configured in
`~/.config/agent0s/shell.json` — see [`plugins.md`](plugins.md).

### Terminals

```
~/.config/alacritty/alacritty.toml
~/.config/foot/foot.ini
~/.config/kitty/kitty.conf
~/.config/ghostty/config
```

**Command:** `agent0s restart terminal`

### Other Configs

| App | Location |
|-----|----------|
| btop | `~/.config/btop/btop.conf` |
| fastfetch | `/etc/fastfetch/config.jsonc` default; `~/.config/fastfetch/config.jsonc` user override |
| lazygit | `~/.config/lazygit/config.yml` |
| starship | `~/.config/starship.toml` |
| git | `~/.config/git/config` |

## Safe Customization Patterns

### Edit User Config Directly

For simple changes, edit files in `~/.config/`:

```bash
# 1. Read current config
cat ~/.config/hypr/bindings.lua

# 2. Backup before changes
cp ~/.config/hypr/bindings.lua ~/.config/hypr/bindings.lua.bak.$(date +%s)

# 3. Make changes with Edit tool

# 4. Apply changes
# - Hyprland: auto-reloads on save, but MUST validate with `hyprctl reload` and `hyprctl configerrors`
# - Agent0S shell: shell.json and user plugin code under ~/.config/agent0s/plugins/ hot-reload on save
# - Menus/launcher: ~/.config/agent0s/extensions/agent0s-menu.jsonc hot-reloads on save
# - Terminals: apply with `agent0s restart terminal` (reloads running terminals; foot picks changes up in new windows)
```

### Reset to Defaults -- ALWAYS SEEK USER CONFIRMATION BEFORE RUNNING

When customizations go wrong:

```bash
# Reset specific config (creates backup automatically)
agent0s refresh shell
agent0s refresh hyprland

# The refresh command:
# 1. Backs up current config with timestamp
# 2. Copies default from $AGENT0S_PATH/config/
# 3. Restarts the component where the refresh needs it (e.g. `refresh shell`)
```

## System Commands

```bash
agent0s update                  # Full system update
agent0s version                 # Show Agent0S version
agent0s debug --no-sudo --print # Debug info (ALWAYS use these flags)
agent0s system lock             # Lock screen
agent0s system shutdown         # Shutdown
agent0s system reboot           # Reboot
```

**IMPORTANT:** Always run `agent0s debug` with `--no-sudo --print` flags to avoid interactive sudo prompts that will hang the terminal.

## Troubleshooting

```bash
# Get debug information (ALWAYS use these flags to avoid interactive prompts)
agent0s debug --no-sudo --print

# Reset specific config to defaults
agent0s refresh <app>

# Refresh specific config file
# config-file path is relative to ~/.config/
# eg. `agent0s refresh config hypr/hyprland.lua` will refresh ~/.config/hypr/hyprland.lua
agent0s refresh config <config-file>

# Full reinstall of configs (nuclear option)
agent0s reinstall
```

## Decision Framework

When user requests system changes:

1. **Is it a stock agent0s command?** Use it directly
2. **Is it a config edit?** Edit in `~/.config/`, never `/usr/share/agent0s/`
3. **Is it a theme customization?** Follow [`theming.md`](theming.md); create a NEW custom theme directory
4. **Is it automation?** Follow [`hooks.md`](hooks.md); use `agent0s hook install` and the hook `.d` directories
5. **Is it a package install?** Use `agent0s pkg add <pkgs...>` (or `agent0s pkg aur add <pkgs...>` for AUR-only packages)
6. **Is it built-in shell/plugin code?** Follow [`plugins.md`](plugins.md); clone it with `agent0s plugin clone`, never edit the packaged copy
7. **Unsure if command exists?** Run `agent0s commands` (or `agent0s <group> --help` for one group)

### Reminder Requests

When the user asks to set a reminder, use `agent0s reminder <minutes> [message]` directly. Convert natural language durations to minutes and title-case short reminder labels when appropriate.

```bash
agent0s reminder 15 "Pickup Jack"
agent0s reminder 60 "Check laundry"
agent0s reminder show
agent0s reminder clear
```

## Out of Scope

This skill intentionally does not cover Agent0S source development. Do not use this skill for:
- Editing files in `/usr/share/agent0s/` (`bin/`, `config/`, `default/`, `shell/`, `themes/`, `migrations/`, etc.)
- Creating or editing migrations
- Running `agent0s dev ...` commands

## Example Requests

- "Change my theme to catppuccin" -> `agent0s theme set catppuccin`
- "Add a keybinding for Super+E to open file manager" -> Check existing bindings first, then use `o.rebind` to replace one or `o.bind` to add one in `~/.config/hypr/bindings.lua`
- "Configure my external monitor" -> Edit `~/.config/hypr/monitors.lua`
- "Make the window gaps smaller" -> Edit `~/.config/hypr/looknfeel.lua`
- "Turn on night light" -> `agent0s toggle nightlight` (for time-based schedules, edit `~/.config/hypr/hyprsunset.conf` profiles, then `agent0s restart hyprsunset`)
- "Set a reminder to pickup jack in 15 minutes" -> `agent0s reminder 15 "Pickup Jack"`
- "Show my reminders" -> `agent0s reminder show`
- "Clear all reminders" -> `agent0s reminder clear`
- "Customize the catppuccin theme colors" -> Overlay: put an edited `colors.toml` in `~/.config/agent0s/themes/catppuccin/`, then re-apply the theme (see `theming.md`)
- "Run a script every time I change themes" -> Install it with `agent0s hook install theme-set <script>`
- "Change how workspace labels are rendered" -> Clone `agent0s.workspaces`, which switches the bar to `<username>.workspaces`, then edit the clone
- "Lock after ten minutes" -> Set `idle.lock` to `600` in `~/.config/agent0s/shell.json`
- "Reset shell/bar to defaults" -> `agent0s refresh shell`
- "Record my screen" -> `agent0s screenrecord --fullscreen`, then `agent0s screenrecord --stop-recording` (see `capture.md`)
- "Report this bug to Agent0S" -> Gather diagnostics and a capture of the problem, then file it (see `contributing.md`)
