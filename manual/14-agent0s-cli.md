# Agent0S CLI

Agent0S is usually controlled through the hotkeys and the Agent0S menu (`Super + Space`). But you can also control it through the `agent0s` CLI. This is particularly helpful when you're having an AI agent work with you on customization or configuration.

The CLI has access to all the internal tooling that is used both via the menu and otherwise. You can see everything that's available by running `agent0s` in the terminal.

It looks something like this:

```
~ ❯ agent0s
Agent0S command center

Usage:
  agent0s <command> [args...]
  agent0s commands [--all] [--json] [--check]
  agent0s <group> --help
  agent0s <group> <command> --help

Common commands:
  agent0s update              Update Agent0S and system packages
  agent0s theme list          List available themes
  agent0s theme set <name>    Apply a theme
  agent0s font list           List available fonts
  agent0s screenshot          Take a screenshot
  agent0s debug               Print debugging information

Groups:
  agent          AI coding agent usage data
  audio          Audio input and output controls
  bar            Agent0S shell bar layout and settings
  battery        Battery status helpers
  bluetooth      Bluetooth device controls
  branch         Agent0S git branch management
  branding       About and screensaver branding
  brightness     Display and keyboard brightness
  capture        Screenshots and screen recording
  channel        Agent0S release channel management
  clipboard      Clipboard helpers
  cmd            Command and shortcut helpers
  config         System configuration helpers
  debug          Diagnostics and support logs
  ...
```

And you can dive deeper on every group:

```
~ ❯ agent0s capture
Capture commands — Screenshots and screen recording:
  agent0s capture qr                                                                                                                                                                                                       Decode a QR code from a screenshot region
  agent0s capture screenrecording [--fullscreen] [--with-desktop-audio] [--with-microphone-audio] [--with-webcam] [--webcam-device=<device>] [--webcam-size=<small|medium|large>] [--resolution=<size>] [--stop-recording]  Start or stop screen recording
  agent0s capture screenrecording with webcam                                                                                                                                                                              Pick a webcam and start a screen recording with it
  agent0s capture screenshot [smart|region|windows|fullscreen] [slurp|copy|save] [--editor=<name>]                                                                                                                         Take a screenshot
  agent0s capture text                                                                                                                                                                                                     Extract text from a screenshot region with OCR
  agent0s capture webcam resize <smaller|larger|reset|small|medium|large>                                                                                                                                                  Resize the active webcam recording overlay
```

Every command takes `--help` too, whether you ask a whole group (`agent0s capture --help`) or a single command (`agent0s capture screenshot --help`).

### Opening the menu from the terminal

The Agent0S menu is scriptable as well, which is handy for your own keybindings. `agent0s menu` opens it at the root, and you can jump straight to any point in the tree by naming it: `agent0s menu summon style.theme` goes right to the theme picker, `agent0s menu toggle system` opens the system menu and closes it again if it's already up, and `agent0s menu close` puts it away.
