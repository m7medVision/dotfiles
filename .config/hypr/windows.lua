-- Window rules — https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Stop apps from stealing fullscreen/maximize on their own (e.g. some
-- Electron apps requesting fullscreen on launch).
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Float + pin browser picture-in-picture popouts instead of tiling them.
hl.window_rule({ match = { title = "^Picture[- ]in[- ][Pp]icture$" }, float = true, pin = true })
