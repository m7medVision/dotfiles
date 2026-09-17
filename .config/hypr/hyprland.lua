-- ██ Hyprland config — migrated from hyprland.conf (hyprlang) to Lua ██
-- hyprlang has been deprecated since Hyprland 0.55 and is scheduled for
-- removal 1-2 releases later; you're on 0.56.2, so this migration keeps
-- the config working going forward. See https://hypr.land/news/26_lua/
--
-- hyprland.conf is left in place (unused) as a reference — Hyprland loads
-- this .lua file instead whenever it's present.
--
-- Split into one file per concern; require() resolves relative to this
-- file's directory (~/.config/hypr/), each with its own Lua scope.

require("envs")
require("monitors")
require("input")
require("looknfeel")
require("windows")
require("bindings")
require("autostart")

-- Your own overrides live here (create the file only if needed):
-- require("overrides")

-- Pull in the active theme's Hyprland overrides (e.g. border colors) last,
-- so they win over hypr/looknfeel.lua above. Resolved by a plain $HOME
-- path (not require()/package.path), so it doesn't depend on any env var
-- being set in the process environment. A theme with no hyprland.lua
-- override just has nothing to load.
local theme_hyprland = os.getenv("HOME") .. "/.local/state/hyprshell/current/theme/hyprland.lua"
local theme_file = io.open(theme_hyprland, "r")
if theme_file then
    theme_file:close()
    dofile(theme_hyprland)
end

-- >>> hyprmoncfg (managed) >>>
-- Re-applies the monitor profile hyprmoncfg activated last, so a layout
-- survives a compositor restart. Loaded last on purpose: it is meant to win
-- over any static hl.monitor() call earlier in the config.
-- Remove this block with: hyprmoncfg unmanage
local hyprmoncfg_current = os.getenv("HOME") .. "/.config/hyprmoncfg/current.lua"
local hyprmoncfg_handle = io.open(hyprmoncfg_current, "r")
if hyprmoncfg_handle then
    hyprmoncfg_handle:close()
    local hyprmoncfg_ok, hyprmoncfg_err = pcall(dofile, hyprmoncfg_current)
    if not hyprmoncfg_ok then
        print("hyprmoncfg: " .. tostring(hyprmoncfg_err))
    end
end
-- <<< hyprmoncfg (managed) <<<
