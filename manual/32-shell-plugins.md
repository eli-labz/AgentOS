# Shell Plugins

The Agent0S desktop runs as a single long-lived Quickshell process called `agent0s-shell`, and almost everything you see on screen is a plugin inside it. The bar is a plugin. So are the panels that drop down from it, the fullscreen overlays like the emoji picker and the clipboard manager, the Agent0S menu itself, the lock screen, the polkit dialog, and the headless services that watch your battery and warm your screen up at night.

That's not just an implementation detail. It means you can turn pieces of the desktop off, swap them out, or write your own without touching a line of Agent0S's source.

The first-party plugins ship with Agent0S and live in `$AGENT0S_PATH/shell/plugins/`. Anything you add yourself — your own experiments, or something you found on GitHub — lives in `~/.config/agent0s/plugins/`. Both are discovered the same way at startup, but built-ins receive trusted shell interfaces while third-party plugins receive a limited interface scoped to their own service and lifecycle. Clones of built-ins keep only the source-specific configuration and UI calls needed for the original behavior.

## Seeing what you have

```
agent0s plugin list
```

That prints every discovered plugin with its id, whether it's enabled, whether it's first-party or third-party, its kinds, and its display name. Add `--json` if you're feeding it to something else.

Plugin ids are namespaced. The built-ins all start with `agent0s.` — `agent0s.clock`, `agent0s.network`, `agent0s.notifications` — and that namespace is reserved, so a third-party plugin can never claim it.

## Turning them on and off

```
agent0s plugin enable agent0s.tailscale
agent0s plugin disable agent0s.weather
```

Or use the menu: _Setup > Plugins_ has Enable, Disable, Add, Clone, and Remove, each with a picker that only offers the plugins that make sense for that action.

Enabled state is stored in `~/.config/agent0s/shell.json`, and the rule differs slightly for the two kinds of plugin. A third-party plugin is enabled exactly when its id appears somewhere in that file — as a bar layout entry, as an entry in `plugins[]`, or as `bar.id`. First-party plugins that aren't bar widgets are the other way around: they're on by default and only turn off by being listed in `disabledPlugins[]`.

A full bar plugin has no off state at all. There's always exactly one bar, so you replace it by enabling another one. Bar widget placement is covered in [the top bar](05-the-top-bar.md).

## Adding a plugin from git

A third-party plugin is just a git repo with a `manifest.json` at its root.

```
agent0s plugin add https://github.com/acme/omarchy-weather.git --enable
```

Before it does anything, it tells you plainly that plugins run as arbitrary, unsandboxed code inside your long-lived shell process, shows you the URL, and asks you to confirm. Take that seriously. The third-party plugin interface does not directly expose authentication services, and a replacement bar receives only limited capabilities for configured non-authentication UI. Visual plugins still share the shell's QML scene and can walk ordinary parent objects, while all plugin code runs with everything your user account can reach. Authentication state is protected separately by keeping those services outside the reachable host object graph. Only add repos you're willing to run, and read them before you enable them.

A replacement bar can render installed widgets, but service-backed third-party widgets may have reduced functionality there because the bar is not allowed to request another plugin's live service object. Switch back to the built-in `agent0s.bar` if such a widget needs its companion service.

Then it clones the repo into a staging directory, validates the manifest, refuses the install if another plugin already claims that id, and moves it into `~/.config/agent0s/plugins/<id>/`. Without `--enable` it asks whether you want it on now, and you can say no and go read the code first. It never runs anything from the plugin, never executes an install hook, and never asks for sudo — it clones files, checks the manifest, and flips a bit over IPC.

Updating is a fast-forward pull of that same checkout:

```
agent0s plugin update acme.weather
agent0s plugin update
```

With no id it updates every git-managed plugin you have. It shows you the diff before applying it, refuses to update if you've got local changes it can't fast-forward past, and rolls back if the new revision fails validation.

```
agent0s plugin remove acme.weather
```

Removal disables the plugin first, then deletes it if it's a git checkout (the repo is still upstream) or unlinks it if it's a symlink. A hand-made plugin folder with no git repo gets moved to a timestamped backup inside the plugins directory instead of being deleted outright.

## Cloning a built-in to modify it

This is my favorite part. If you want to change how a built-in widget behaves, don't edit the files under `$AGENT0S_PATH` — those belong to the package and the next update will overwrite them. Clone it instead:

```
agent0s plugin clone agent0s.clock
```

That copies the whole plugin into `~/.config/agent0s/plugins/dhh.clock` (your username, not mine), renames it to "My Clock", enables it, and switches the shell over from the built-in to your copy — keeping an existing bar widget's position and settings. Add `--edit` to open the new directory in your `$EDITOR` right away, which is what the menu's _Setup > Plugins > Clone Plugin_ does for you.

The username prefix keeps your clone's id yours, so sharing it doesn't collide with anyone else's. Calls made to the original built-in id get routed to your clone, so nothing that referred to `agent0s.clock` needs updating. And if you make a mess of it, `agent0s plugin remove dhh.clock` puts the built-in back.

Saving a file anywhere under `~/.config/agent0s/plugins/` reloads the plugin code automatically, so you can leave the editor open and watch your changes land.

## Writing your own

A plugin is a directory with a `manifest.json` and some QML. The manifest declares `schemaVersion: 1`, an `id`, `name`, `version`, one or more `kinds`, and an `entryPoints` object pointing at the QML file for each kind:

| Kind | What it is |
|------|------------|
| `bar-widget` | A component the active bar can drop into a section |
| `panel` | A persistent or summoned floating window |
| `overlay` | A fullscreen overlay |
| `menu` | A summoned menu surface |
| `service` | A headless singleton with no UI |
| `bar` | A full bar that replaces the built-in one |

A plugin can declare several kinds at once — the media plugin is both a `service` and a `bar-widget`. Bar widgets get an extra `barWidget` block with a display name, a category, an optional `defaultSection`, and `allowMultiple`, which says whether it makes sense to have more than one on the bar. Most widgets set it to `false`; spacers and indicators set it to `true`.

Before you publish anything, check it:

```
agent0s plugin validate ./my-plugin
```

That runs the same checks the shell does at load time: the schema version, the required fields, an id that isn't reserved, entry points that are safe relative paths and actually exist, an entry point for every kind you claimed, and no symlinks anywhere inside the folder.

For the full picture, the source is the documentation: `shell/README.md` in the Agent0S repo covers the manifest schema, the shell's IPC contract, and the exact shape of `shell.json`, and `shell/plugins/README.md` lists every first-party plugin with its id, kinds, and entry points.

## Sharing yours with the world

Once you've made something you like, put it in a public git repo. That's the whole distribution mechanism — anyone can then run `agent0s plugin add` against your URL and have it running in seconds.

To help people actually find it, list it at [agent0splugins.com](https://agent0splugins.com). That's the community directory of Agent0S shell plugins, and it's the first place to look when you're wondering whether someone has already built the widget you're about to write. Browse it before you start!
