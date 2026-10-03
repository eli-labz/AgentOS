-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Agent0S's bootstrap keeps path setup out of this user config.
dofile((os.getenv("AGENT0S_PATH") or "/usr/share/agent0s") .. "/default/hypr/bootstrap.lua")

-- Disable all Agent0S default bindings. Add your own in hypr/bindings.lua.
-- agent0s_default_bindings = false
--
-- Or disable only bindings for Agent0S's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- agent0s_preinstalled_bindings = false

-- Load Agent0S defaults.
require("default.hypr.agent0s")

-- Put your personal overrides in these files. They're loaded after Agent0S's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })
