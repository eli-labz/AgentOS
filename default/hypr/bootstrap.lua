-- Hyprland bootstrap for Agent0S's Lua module path.

local home = os.getenv("HOME")
local reload_prefixes = {
  "default.hypr",
  "hypr",
  "agent0s.current.theme",
}

local function should_reload_module(module)
  for _, prefix in ipairs(reload_prefixes) do
    if module == prefix or module:sub(1, #prefix + 1) == prefix .. "." then
      return true
    end
  end

  return false
end

local modules_to_reload = {}
for module in pairs(package.loaded) do
  if should_reload_module(module) then
    table.insert(modules_to_reload, module)
  end
end

for _, module in ipairs(modules_to_reload) do
  package.loaded[module] = nil
end

-- Load generated state from ~/.local/state, user modules from ~/.config, and
-- Agent0S defaults from $AGENT0S_PATH.
package.path = home
  .. "/.local/state/?.lua;"
  .. home
  .. "/.config/?.lua;"
  .. (os.getenv("AGENT0S_PATH") or "/usr/share/agent0s")
  .. "/?.lua;"
  .. package.path
