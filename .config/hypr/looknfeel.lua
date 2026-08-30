-- Look & feel
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        resize_on_border = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding = 0,
        shadow   = { enabled = false },
        blur     = { enabled = false },
    },

    group = {
        groupbar = {
            font_size   = 12,
            font_family = "monospace",
        },
    },

    animations = {
        enabled = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    misc = {
        key_press_enables_dpms  = true,
        mouse_move_enables_dpms = true,
    },
})

-- Animation curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 5, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "easeOutQuint" })
hl.animation({ leaf = "fade",       enabled = true, speed = 5, bezier = "easeInOutCubic" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "border",     enabled = true, speed = 5, bezier = "easeOutQuint" })

-- Scroll nicely in terminals — NOTE: `scrolltouchpad` windowrule was not a
-- valid field in Hyprland 0.56.2 (config error), so these stay disabled:
-- hl.window_rule({ name = "scroll-foot",  match = { class = "^(foot|kitty|Alacritty)$" }, scrolltouchpad = 1.5 })
-- hl.window_rule({ name = "scroll-ghostty", match = { class = "^(com\\.mitchellh\\.ghostty)$" }, scrolltouchpad = 0.2 })
