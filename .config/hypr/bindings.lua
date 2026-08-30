local mainMod = "SUPER"

-- Apps
hl.bind(mainMod .. " + Return",       hl.dsp.exec_cmd("kitty"))                -- terminal (foot/ghostty also fine)
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("helium-browser"))     -- default browser
hl.bind(mainMod .. " + SHIFT + F",    hl.dsp.exec_cmd("nautilus"))             -- file manager
hl.bind(mainMod .. " + SPACE",        hl.dsp.exec_cmd("vicinae toggle"))       -- launcher

-- Tiling
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))   -- dwindle only
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.window.float())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())                              -- real fullscreen
-- Old "fullscreen, 2" (tiled fullscreen, keeps bar visible) has no direct Lua
-- dispatcher equivalent yet — falling back to the raw hyprctl call to keep
-- behavior identical. Verify this still does what you expect.
hl.bind(mainMod .. " + CTRL + F", hl.dsp.exec_cmd("hyprctl dispatch fullscreen 2"))
hl.bind(mainMod .. " + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))   -- maximized

-- Pop-out window (pin + float)
hl.bind(mainMod .. " + O", function()
    hl.dispatch(hl.dsp.window.pin())
    hl.dispatch(hl.dsp.window.float())
end)

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Workspaces 1-10 via XKB keycodes (code:10-19), same trick some distros use
for i = 1, 10 do
    local code = 9 + i -- code:10 .. code:19
    hl.bind(mainMod .. " + code:" .. code,          hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + code:" .. code,  hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + TAB",        hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + TAB", hl.dsp.focus({ workspace = "previous" }))

-- Scratchpad
hl.bind(mainMod .. " + S",          hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mainMod .. " + SHIFT + S",  hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Move whole workspace between monitors
hl.bind(mainMod .. " + SHIFT + ALT + left",  hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + ALT + right", hl.dsp.workspace.move({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + ALT + up",    hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + ALT + down",  hl.dsp.workspace.move({ monitor = "d" }))

-- Window grouping (tabs) & resize mode
hl.bind(mainMod .. " + G",         hl.dsp.group.toggle(), { description = "Toggle window grouping" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.window.move({ out_of_group = true }), { description = "Move window out of group" })

hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.move({ into_group = "l" }), { description = "Move window into group (left)" })
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.move({ into_group = "r" }), { description = "Move window into group (right)" })
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.move({ into_group = "u" }), { description = "Move window into group (up)" })
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.move({ into_group = "d" }), { description = "Move window into group (down)" })

hl.bind(mainMod .. " + CTRL + left",  hl.dsp.group.prev(), { description = "Focus previous window in group" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.group.next(), { description = "Focus next window in group" })

-- Resize mode: Super+R enters, arrows resize (Shift = bigger steps), Escape/Enter exits.
hl.define_submap("resize", function()
    hl.bind("left",  hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
    hl.bind("right", hl.dsp.window.resize({ x = 20,  y = 0, relative = true }), { repeating = true })
    hl.bind("up",    hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
    hl.bind("down",  hl.dsp.window.resize({ x = 0, y = 20,  relative = true }), { repeating = true })

    hl.bind("SHIFT + left",  hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
    hl.bind("SHIFT + right", hl.dsp.window.resize({ x = 100,  y = 0, relative = true }), { repeating = true })
    hl.bind("SHIFT + up",    hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
    hl.bind("SHIFT + down",  hl.dsp.window.resize({ x = 0, y = 100,  relative = true }), { repeating = true })

    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("return", hl.dsp.submap("reset"))
end)
hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { description = "Enter resize mode" })

-- Desktop shell (quickshell) — IPC calls into the already-running shell that
-- autostart.lua starts, so these are instant, not cold starts. The plugin ids
-- are the shell's internal names and have to be spelled exactly.
-- Super+SPACE stays on vicinae and Super+ESCAPE stays on hyprlock.
--
-- Spelled absolute on purpose: Hyprland applies hl.env only at startup, so a
-- bind fired after a plain `hyprctl reload` still sees the old PATH.
local shell_bin = os.getenv("HOME") .. "/.local/share/hyprshell/bin/shell-ipc-run"
hl.bind(mainMod .. " + CTRL + V", hl.dsp.exec_cmd("vicinae deeplink 'vicinae://launch/clipboard/history'"), { description = "Clipboard history" })
hl.bind(mainMod .. " + CTRL + E", hl.dsp.exec_cmd("rofimoji --selector wofi"),                              { description = "Emoji picker" })
hl.bind(mainMod .. " + CTRL + A", hl.dsp.exec_cmd(shell_bin .. " shell toggle raw.audio"),                  { description = "Audio panel" })
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(shell_bin .. " shell toggle raw.bluetooth"),              { description = "Bluetooth panel" })
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.exec_cmd(shell_bin .. " shell toggle raw.menu '{\"menu\":\"root\"}'"), { description = "Command menu" })

-- Utilities
hl.bind(mainMod .. " + ESCAPE",         hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + SPACE",  hl.dsp.dpms())   -- blank screen (toggle)

-- Night light toggle (hyprsunset)
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("pkill hyprsunset || hyprsunset -t 4500"))

-- Screenshots (Print=screenshot, Super+Print=color picker)
hl.bind("PRINT",                 hl.dsp.exec_cmd("shot"))         -- region → file + clipboard
hl.bind("SHIFT + PRINT",         hl.dsp.exec_cmd("shot full"))
hl.bind(mainMod .. " + PRINT",   hl.dsp.exec_cmd("hyprpicker -a"))

-- Notifications (dunst)
hl.bind(mainMod .. " + comma",         hl.dsp.exec_cmd("dunstctl close"))
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.exec_cmd("dunstctl close-all"))
hl.bind(mainMod .. " + CTRL + comma",  hl.dsp.exec_cmd("dunstctl set-paused toggle"))

-- Media & hardware keys (locked = fires even when the session is locked)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pamixer -t"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("pamixer --default-source -t"), { locked = true })
hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 1"), { locked = true })
hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 1"), { locked = true })
hl.bind("SHIFT + XF86AudioMute",      hl.dsp.exec_cmd("pamixer -t --sink 1"), { locked = true })   -- switch output? see pamixer --list-sinks

hl.bind("XF86MonBrightnessUp",         hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true })
hl.bind("XF86MonBrightnessDown",       hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true })
hl.bind("SHIFT + XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 100%"), { locked = true })
hl.bind("SHIFT + XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 1%"), { locked = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
