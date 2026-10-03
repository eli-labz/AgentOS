-- Keep only your personal keybinding overrides here. Add new bindings with
-- o.bind or replace defaults with o.rebind.

-- See current bindings and descriptions:
--   agent0s menu keybindings --print

-- To disable every Agent0S default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.agent0s"), then add
-- only the bindings you want below:
--   agent0s_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   agent0s_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding. o.rebind takes the same arguments as o.bind.
-- This example replaces the default file manager with Flea.
-- o.rebind("SUPER + SHIFT + F", "File manager", { launch = "flea" })

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "agent0s-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "agent0s-shell shell toggle agent0s.emojis")
