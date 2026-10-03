-- Restore workspace layouts saved by agent0s-hyprland-workspace-layout-toggle.

local paths = require("default.hypr.paths")
local require_all = require("default.hypr.require_all")

local layouts_dir = paths.state_home .. "/agent0s/workspace-layouts"

require_all.files(layouts_dir, "agent0s.workspace-layouts", { reload = true })
