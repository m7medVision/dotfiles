-- Autostart (runs once, only in Hyprland)
hl.on("hyprland.start", function()
    -- Fix slow first app launch + make portals/screen-share work
    hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")

    hl.exec_cmd("udiskie --automount --no-notify --no-tray")   -- USB automount
    hl.exec_cmd("dunst")                   -- notification daemon
    hl.exec_cmd("powerprofiles-apply")     -- battery optimization
    hl.exec_cmd("xsettingsd")              -- XSettings manager so XWayland GTK3 apps hot-reload theme

    -- Voice-to-text daemon, started here rather than by its systemd unit:
    -- voxtype.service is WantedBy=graphical-session.target, and this session
    -- (gdm -> start-hyprland, no uwsm) never activates that target, so the
    -- enabled unit never actually fired at login. Disabled now to avoid a
    -- second daemon fighting over the socket if that ever changes.
    -- systemd-cat keeps the daemon + OSD log in the journal, since the
    -- compositor's stdout is not somewhere you can go read it.
    --   config: voxtype configure  (~/.config/voxtype/config.toml)
    --   keys:   Super+V toggles, Super+Shift+V cancels (see bindings.lua)
    --   logs:   journalctl --user -t voxtype -f
    hl.exec_cmd("systemd-cat -t voxtype -- voxtype daemon")

    -- Bar + panels + tray + polkit agent, all inside one Quickshell process.
    -- Supervised: the launcher relaunches it on a crash and tees its log to
    -- the journal.
    --   config:  ~/.config/hyprshell/shell.json
    --   restart: restart-shell
    --   logs:    journalctl --user -t hyprshell -f
    hl.exec_cmd(os.getenv("HOME") .. "/.local/share/hyprshell/bin/launch-shell")

    hl.exec_cmd("vicinae server")          -- daemon so Super+Space toggles instantly
end)
