-- Autostart (runs once, only in Hyprland)
hl.on("hyprland.start", function()
    -- Fix slow first app launch + make portals/screen-share work
    hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")

    hl.exec_cmd("udiskie --automount --no-notify --no-tray")   -- USB automount
    hl.exec_cmd("dunst")                   -- notification daemon
    hl.exec_cmd("powerprofiles-apply")     -- battery optimization
    hl.exec_cmd("xsettingsd")              -- XSettings manager so XWayland GTK3 apps hot-reload theme

    -- Bar + panels + tray + polkit agent, all inside one Quickshell process.
    -- Supervised: the launcher relaunches it on a crash and tees its log to
    -- the journal.
    --   config:  ~/.config/hyprshell/shell.json
    --   restart: restart-shell
    --   logs:    journalctl --user -t hyprshell -f
    hl.exec_cmd(os.getenv("HOME") .. "/.local/share/hyprshell/bin/launch-shell")

    hl.exec_cmd("vicinae server")          -- daemon so Super+Space toggles instantly
end)
