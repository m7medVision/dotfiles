-- Monitors — workspace split by ROLE, so one config works at every location.
--
-- Nothing here names a specific display. Screens are matched by role instead:
--
--   internal panel (eDP/LVDS/DSI)  -> workspaces 1-5
--   whatever external is attached   -> workspaces 6-10
--
-- Naming a monitor is what kept breaking this: connector names move with the
-- cable or port (HDMI-A-5 became DP-3 when the work display was replugged),
-- and the model differs per location entirely — home is a Xiaomi on HDMI-A-5,
-- work is an LG on DP-3. A rule naming either one silently matches nothing at
-- the other place, and Hyprland then falls back to auto-creating an
-- off-scheme workspace (that stray "11" on the work display) and lets both
-- screens draw from one pool.
--
-- Roles are re-resolved on every monitor.added, so plugging in at home or
-- work re-pins the split with no edits.
--
-- Geometry (mode, scale, position) is deliberately NOT set here. hyprmoncfg
-- owns that: its managed block at the end of hyprland.lua loads last and is
-- meant to win. Use SUPER+CTRL+D to change resolution or arrangement.

local LAPTOP   = { first = 1, last = 5 }
local EXTERNAL = { first = 6, last = 10 }

local function is_internal(name)
    return name:match("^eDP") ~= nil
        or name:match("^LVDS") ~= nil
        or name:match("^DSI") ~= nil
end

-- Classify one monitor by role into the internal/external pair, first-wins.
local function classify(roles, name)
    if not name then
        return
    end
    if is_internal(name) then
        roles.internal = roles.internal or name
    else
        roles.external = roles.external or name
    end
end

-- Walk the monitor id space; there is no "all monitors" accessor. Ids are NOT
-- contiguous after a hotplug — unplugging a display frees its id and the
-- replacement gets the next free one, so a session that has swapped displays
-- reports e.g. id 0 and id 2 with nothing at 1. A missing id yields nil rather
-- than raising, so this scans a generous fixed window instead of stopping at
-- the first gap.
local MAX_MONITOR_ID = 31

local function roles_by_id()
    local roles = {}
    for id = 0, MAX_MONITOR_ID do
        local monitor = hl.get_monitor(tostring(id))
        if monitor then
            classify(roles, monitor.name)
        end
    end
    return roles
end

-- Re-pin 1-5 and 6-10 onto the screens currently attached.
--
-- `added` is the monitor a monitor.added signal handed us. It is REQUIRED for
-- the hotplug case: a display is not yet enumerable by id at the moment its
-- add signal fires, so roles_by_id() alone resolves no external and the new
-- screen falls through to an off-scheme workspace. The signal's own object
-- has the name already, so fold it in.
local function apply_split(added)
    local roles = roles_by_id()
    if added then
        -- Guard the property read: a signal can outlive the display it names
        -- (unplug immediately after plug-in), leaving an expired object.
        local ok, name = pcall(function() return added.name end)
        if ok then
            classify(roles, name)
        end
    end

    if not roles.internal then
        return
    end
    -- Single-screen session: keep 6-10 on the panel so SUPER+6 still lands on
    -- an in-scheme workspace instead of an auto-created number off the end.
    -- Plugging an external in re-runs this and migrates them across.
    local internal = roles.internal
    local external = roles.external or internal

    for i = LAPTOP.first, LAPTOP.last do
        hl.workspace_rule({ workspace = tostring(i), monitor = internal, persistent = true })
    end
    for i = EXTERNAL.first, EXTERNAL.last do
        hl.workspace_rule({ workspace = tostring(i), monitor = external, persistent = true })
    end
    -- The workspace each screen shows at login.
    hl.workspace_rule({ workspace = tostring(LAPTOP.first),   monitor = internal, persistent = true, default = true })
    hl.workspace_rule({ workspace = tostring(EXTERNAL.first), monitor = external, persistent = true, default = true })
end

apply_split()

-- The subscription must be anchored where the collector cannot reach it: an
-- unheld local goes out of scope when this chunk finishes, the subscription
-- is GC'd, and the handler silently stops firing.
_G.hypr_workspace_split = hl.on("monitor.added", apply_split)
