# First-party plugins

These plugins ship with Agent0S and are discovered by the shell at startup.
They use the same `manifest.json` contract as third-party plugins; the
only difference is that the shell flags them with `__isFirstParty: true`.
First-party non-bar plugins are enabled unless listed in `disabledPlugins[]`;
`agent0s.bar` is the default bar option and becomes inactive only while another
`kind: "bar"` plugin is selected. Services and keep-loaded panels are mounted
at startup; other panels, overlays, and menus are loaded on demand.

User-installed plugins live alongside these conceptually but on disk under
`~/.config/agent0s/plugins/<plugin-id>/` rather than in this directory.

| Plugin        | id                        | kinds                   | entry point                           |
|---------------|---------------------------|-------------------------|---------------------------------------|
| Bar           | `agent0s.bar`             | `bar`                   | `bar/Bar.qml`                         |
| Image picker  | `agent0s.image-picker`    | `overlay`               | `image-picker/ImagePicker.qml`        |
| Emojis        | `agent0s.emojis`          | `overlay`               | `emojis/Emojis.qml`                   |
| Clipboard mgr | `agent0s.clipboard`       | `overlay`               | `clipboard/Clipboard.qml`             |
| Reminders     | `agent0s.reminders`       | `overlay`               | `reminders/ReminderFlow.qml`          |
| Agent0S menu  | `agent0s.menu`            | `menu`, `bar-widget`    | `menu/Menu.qml`, `menu/BarWidget.qml` |
| Notifications | `agent0s.notifications`   | `service`               | `notifications/Service.qml`           |
| Audio         | `agent0s.audio`           | `bar-widget`            | `panels/audio/Panel.qml`              |
| Bluetooth     | `agent0s.bluetooth`       | `bar-widget`            | `panels/bluetooth/Panel.qml`          |
| Clock         | `agent0s.clock`           | `bar-widget`            | `panels/clock/BarWidget.qml`          |
| Monitor       | `agent0s.monitor`         | `bar-widget`            | `panels/monitor/Panel.qml`            |
| Network       | `agent0s.network`         | `bar-widget`            | `panels/network/Panel.qml`            |
| Power         | `agent0s.power`           | `bar-widget`            | `panels/power/Panel.qml`              |
| Tailscale     | `agent0s.tailscale`       | `bar-widget`            | `panels/tailscale/Panel.qml`          |
| Agents   | `agent0s.agents`     | `bar-widget`            | `agents/Panel.qml`               |
| Weather       | `agent0s.weather`         | `bar-widget`            | `panels/weather/BarWidget.qml`        |
| Media         | `agent0s.media`           | `service`, `bar-widget` | `services/media/Service.qml`, `services/media/BarWidget.qml` |
| Battery       | `agent0s.battery`         | `service`               | `services/battery/Service.qml`        |
| Idle          | `agent0s.idle`            | `service`               | `services/idle/Service.qml`           |
| Night light   | `agent0s.nightlight`      | `service`               | `services/nightlight/Service.qml`     |
| Lock screen   | `agent0s.lock`            | `service`               | `lock/Service.qml`                    |
| OSD           | `agent0s.osd`             | `panel`                 | `osd/Osd.qml`                         |
| Polkit agent  | `agent0s.polkit`          | `service`               | `polkit/PolkitAgent.qml`              |

First-party bar-only widgets also carry manifests next to their QML files,
e.g. `bar/widgets/Workspaces.manifest.json`. Rich popup widgets live in their
own plugin directories, each with its own `manifest.json`.

## Bar

The built-in status bar and default full-bar option. Layout lives in the
top-level `bar:` subtree of `~/.config/agent0s/shell.json` (with the shell
providing [`config/agent0s/shell.json`](../../config/agent0s/shell.json) when
the user has no file). See [`bar/README.md`](bar/README.md) for the widget catalogue
and customization schema.

## Image picker

Fullscreen image-grid selector overlay. Used by `agent0s-menu-images`
(wallpaper picker) and `agent0s-theme-switcher` (theme picker) and any
other caller that wants to present a directory of images with previews.

Two ways to drive it:

- Shell-level summon: `agent0s-shell shell summon agent0s.image-picker '<jsonPayload>'`.
  The payload can carry `imageDirs`, `imageRows`, `selectedImage`,
  `selectionFile`, `doneFile`, `showLabels`, `filterable`. Best for
  in-shell callers that already speak JSON.
- Direct IPC target: `agent0s-shell image-selector open <imageDirs> <imageRowsB64> <selectedImage> <selectionFile> <doneFile> <showLabels> <filterable>`.
  Positional args; `imageRowsB64` is base64-encoded so embedded newlines /
  tabs survive the bash argv handoff. This is what `agent0s-menu-images`
  uses. Colors come from the central shell theme singleton; there is no
  per-call override surface.

The selection round-trip remains file-based: callers create a
`selection_file` and `done_file` (both `mktemp`), pass the paths, and
poll `done_file` for existence. The plugin writes the chosen path into
`selection_file` and touches `done_file` when it's done. `cancel` IPC
clears it without writing a selection.

The plugin has `keepLoaded: true` so the layer-shell window survives
between summons within a single shell session.

## Lock screen

Session-lock surface using Quickshell's native `WlSessionLock` and two
separate PAM services: `agent0s-lock-password` for password auth and,
only when fingerprints are enrolled, `agent0s-lock-fingerprint` for
fingerprint auth. It mirrors the previous lock screen field dimensions,
colors, blurred wallpaper, placeholder, and Hyprland-driven corners.
The plugin sets `keepLoaded: true` so a plugin hot-reload (for example
an installed bar widget changing on disk) does not destroy the lock
client while Hyprland still holds the session lock.

## Polkit agent

Theme-aware authentication dialog for privileged actions. It uses
Quickshell's native `Quickshell.Services.Polkit.PolkitAgent` backend and
runs inside the long-lived `agent0s-shell` process, replacing the old
`polkit-gnome-authentication-agent-1` autostart.

## Agent0S menu

Quickshell-powered Agent0S command menu.
The menu UI lives in `menu/Menu.qml` as a first-party `menu` plugin and is
summoned through the shell (`agent0s-shell shell summon agent0s.menu ...`),
so it shares the long-running `agent0s-shell` process instead of starting a
second Quickshell instance.

The menu definition lives outside the shell host code:

- defaults: `default/agent0s/agent0s-menu.jsonc`
- user extensions: `~/.config/agent0s/extensions/agent0s-menu.jsonc`

The shell parses both JSONC files at startup (with `watchChanges: true`
so edits take effect without a restart), evaluates `when:` / `checked:`
bash expressions in a single batched subprocess, and executes the
selected `action:` string directly via `Quickshell.execDetached`. The
long-running shell process keeps the parsed menu in memory, so the
keybind → IPC → visible path costs ~30ms cold.

## Coming soon

- `agent0s.theme-switcher` — folds theme switching into the shell.
