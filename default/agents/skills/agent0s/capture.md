# Capture and Sharing

Read this before taking screenshots or screen recordings, extracting text from
the screen, or sharing files with other machines.

## Screenshots

```bash
agent0s screenshot                            # Interactive smart-region flow
agent0s capture screenshot region             # Select a region
agent0s capture screenshot windows            # Pick a window
agent0s capture screenshot fullscreen save    # Full screen, straight to disk (no editor)
```

The first argument picks the mode (`smart|region|windows|fullscreen`), the
second what happens with it (`slurp|copy|save`). `save` skips the annotation
editor and prints the saved path. Screenshots land in the configured Pictures
directory (override with `AGENT0S_SCREENSHOT_DIR`).

## Screen Recording

```bash
agent0s screenrecord --fullscreen             # Start recording the full screen
# ...exercise whatever you want on film...
agent0s screenrecord --stop-recording         # Stop; prints the saved path
```

Optional flags: `--with-desktop-audio`, `--with-microphone-audio`,
`--with-webcam` (plus `--webcam-device=` and `--webcam-size=`), and
`--resolution=<size>`. Without `--fullscreen` a region picker opens first.
Recordings land in the configured Videos directory (override with
`AGENT0S_SCREENRECORD_DIR`). Resize a live webcam overlay with
`agent0s capture webcam resize <smaller|larger|reset|small|medium|large>`.

If recording fails to start, rerun with `AGENT0S_SCREENRECORD_DEBUG=true` to
collect a log at `/tmp/agent0s-screenrecord.log` worth attaching to a bug
report.

## Text Capture (OCR)

```bash
agent0s capture text    # Select a region; extracted text goes to the clipboard
```

## Sharing Files

```bash
agent0s share clipboard               # Share the clipboard via LocalSend
agent0s share file <path...>          # Share files with nearby devices
agent0s share folder <path>           # Share a folder

agent0s tailscale send <machine> <file...>    # Taildrop to a tailnet machine
agent0s tailscale receive [directory]         # Save incoming Taildrop files
```

Shrink large captures before sharing them:

```bash
agent0s transcode <input> [format] [resolution]   # Re-encode pictures/videos for sharing
```
