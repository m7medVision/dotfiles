-- Monitors — explicit, keeps workspaces separated per screen (no mixing)
-- eDP-1 = laptop panel (A) at 0,0 ; HDMI-A-5 = external (B) at 1920,0
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "0x0",
    scale    = 1,
})
hl.monitor({
    output   = "HDMI-A-5",
    mode     = "preferred",
    position = "1920x0",
    scale    = 1,
})

-- Bind workspaces 1-5 → eDP-1 and 6-10 → HDMI-A-5, persistent so they stay on that monitor
-- This stops Hyprland from moving workspace 1 to HDMI when you press SUPER+1 on that screen.
for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1", persistent = true })
end
for i = 6, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-5", persistent = true })
end
-- Make each monitor start with a default workspace
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", persistent = true, default = true })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-5", persistent = true, default = true })
