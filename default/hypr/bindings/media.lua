-- Volume, brightness, keyboard backlight, and touchpad controls.
o.bind("XF86AudioRaiseVolume", "Volume up", "agent0s-audio-output-volume raise", { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "agent0s-audio-output-volume lower", { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute", "agent0s-audio-output-volume mute-toggle", { locked = true })
o.bind("XF86AudioMicMute", "Mute microphone", "agent0s-audio-input-mute", { locked = true })
o.bind("XF86MonBrightnessUp", "Brightness up", "agent0s-brightness-display +5%", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", "agent0s-brightness-display 5%-", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessUp", "Brightness maximum", "agent0s-brightness-display 100%", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessDown", "Brightness minimum", "agent0s-brightness-display 1%", { locked = true, repeating = true })
o.bind("XF86KbdBrightnessUp", "Keyboard brightness up", "agent0s-brightness-keyboard up", { locked = true, repeating = true })
o.bind("XF86KbdBrightnessDown", "Keyboard brightness down", "agent0s-brightness-keyboard down", { locked = true, repeating = true })
o.bind("XF86KbdLightOnOff", "Keyboard backlight cycle", "agent0s-brightness-keyboard cycle", { locked = true })
o.bind_toggle("XF86TouchpadToggle", "Toggle touchpad", "touchpad", { locked = true })
o.bind("XF86TouchpadOn", "Enable touchpad", "agent0s-toggle-touchpad on", { locked = true })
o.bind("XF86TouchpadOff", "Disable touchpad", "agent0s-toggle-touchpad off", { locked = true })

-- Precise volume and brightness controls.
o.bind("ALT + XF86AudioRaiseVolume", "Volume up precise", "agent0s-audio-output-volume +1", { locked = true, repeating = true })
o.bind("ALT + XF86AudioLowerVolume", "Volume down precise", "agent0s-audio-output-volume -1", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", "agent0s-brightness-display +1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", "agent0s-brightness-display 1%-", { locked = true, repeating = true })

-- Media controls.
o.bind("XF86AudioNext", "Next track", "agent0s-shell media next", { locked = true })
o.bind("ALT + XF86AudioPlay", "Next track", "agent0s-shell media next", { locked = true })
o.bind("XF86AudioPause", "Pause", "agent0s-shell media playPause", { locked = true })
o.bind("XF86AudioPlay", "Play", "agent0s-shell media playPause", { locked = true })
o.bind("XF86AudioPrev", "Previous track", "agent0s-shell media previous", { locked = true })
o.bind("ALT + SHIFT + XF86AudioPlay", "Previous track", "agent0s-shell media previous", { locked = true })
o.bind("XF86Eject", "Eject media", "eject", { locked = true })

o.bind("SHIFT + XF86AudioMute", "Switch audio output", "agent0s-audio-output-switch", { locked = true })
o.bind("SHIFT + XF86AudioPause", "Switch media source", "agent0s-audio-source-switch", { locked = true })
o.bind("SHIFT + XF86AudioPlay", "Switch media source", "agent0s-audio-source-switch", { locked = true })
