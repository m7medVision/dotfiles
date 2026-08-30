-- Environment (force Wayland everywhere)
hl.env("XCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")
-- Make screen sharing work in Google Meet / Discord inside Hyprland
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- ── Desktop shell (quickshell) ──────────────────────────────────────────────
-- The bar, panels, tray and polkit agent all run inside one quickshell
-- process. Its source is a fully-owned, fixed-path config at
-- ~/.local/share/hyprshell (no upstream tracking, no env-var indirection) —
-- its own QML hardcodes that path directly. It still shells out to the
-- helper scripts in that tree's bin/, so that dir has to be on PATH for
-- children Hyprland spawns.
local shell_bins = { os.getenv("HOME") .. "/.local/bin", os.getenv("HOME") .. "/.local/share/hyprshell/bin" }
local path_entries = { shell_bins[1], shell_bins[2] }
for entry in (os.getenv("PATH") or "/usr/local/bin:/usr/bin"):gmatch("[^:]+") do
    if entry ~= shell_bins[1] and entry ~= shell_bins[2] then
        table.insert(path_entries, entry)
    end
end
hl.env("PATH", table.concat(path_entries, ":"))

-- Hybrid GPU (Intel renders desktop, RTX 3050 on demand via `prime-run <app>`).
-- If you see glitches, uncomment to pin Hyprland to the iGPU:
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/card0")
