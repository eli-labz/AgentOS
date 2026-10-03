# Themes, Backgrounds, and Fonts

Read this before changing themes, backgrounds, fonts, or theme colors.

## Theme Commands

```bash
agent0s theme list              # Show available themes
agent0s theme current           # Show current theme
agent0s theme set <name>        # Apply theme ("Tokyo Night" and "tokyo-night" both work)
agent0s theme bg next           # Cycle background
agent0s theme install <url>     # Install from git repo
```

## Making a New Theme

1. Create a directory under `~/.config/agent0s/themes`.
2. See how an existing theme is done via `/usr/share/agent0s/themes/catppuccin`.
3. Download a matching background (or several) from the internet and put them in `~/.config/agent0s/themes/<name-of-new-theme>/backgrounds/`.
4. When done with the theme, run `agent0s theme set "Name of new theme"`.

Additional user backgrounds for any theme (stock or custom) go in
`~/.config/agent0s/backgrounds/<theme-slug>/`.

## What a Theme Installed From a Repo May Not Contain

A theme the user wrote by hand in `~/.config/agent0s/themes` is unrestricted, as
are Agent0S's own themes. From a theme cloned by `agent0s theme install`, Agent0S
drops only what runs code: any `*.lua` (Hyprland requires a theme's
`hyprland.lua` and `gum_env.lua` at login, Neovim loads `neovim.lua` at startup),
the terminal configs `alacritty.toml`, `foot.ini`, `ghostty.conf` and
`kitty.conf` (each names the program the terminal launches), and `vscode.json`
(names a VS Code extension to install). Those are regenerated from `colors.toml`
through `$AGENT0S_PATH/default/themed/*.tpl`, and named on stderr.

Everything else a cloned theme ships is kept, including `btop.theme`,
`chromium.theme`, `helix.toml`, `icons.theme`, `keyboard.rgb` and `shell.toml`.
Agent0S tells a cloned theme from the user's own by the `.git` directory a clone
leaves behind.

To change how Agent0S themes an app for every theme, write the template rather
than the theme: `~/.config/agent0s/themed/<config-name>.tpl` overrides the
built-in one. See `docs/theming.md` in the Agent0S repo.

## Customizing a Stock Theme

Never edit stock themes under `/usr/share/agent0s/themes/` — changes are lost
on update. Two safe options:

Both write into `~/.config/agent0s/themes`, where a theme the user wrote is
unrestricted — the list above applies only to a theme cloned from a repo.

**Overlay (preferred for small tweaks):** create a user theme directory with
the SAME slug containing only the files you want to change. When the theme is
applied, the stock theme is copied first and your files win on top:

```bash
mkdir -p ~/.config/agent0s/themes/catppuccin
cp /usr/share/agent0s/themes/catppuccin/colors.toml ~/.config/agent0s/themes/catppuccin/
# Edit the copied colors.toml, then re-apply:
agent0s theme set catppuccin
```

**Fork:** copy the whole stock theme under a new name for a fully independent
variant:

```bash
cp -r /usr/share/agent0s/themes/catppuccin ~/.config/agent0s/themes/catppuccin-custom
# Edit ~/.config/agent0s/themes/catppuccin-custom/, then:
agent0s theme set catppuccin-custom
```

## Fonts

```bash
agent0s font list               # Available fonts
agent0s font current            # Current font
agent0s font set <name>         # Change font
```
