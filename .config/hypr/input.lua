-- Input — us,ara + GNOME-style touchpad
hl.config({
    input = {
        kb_layout = "us,ara",
        -- Swap layouts: Alt+Shift (mimics GNOME's grp:win_space_toggle)
        kb_options = "grp:alt_shift_toggle",
        -- Also use Caps Lock as compose key — uncomment if you want it:
        -- kb_options = "grp:alt_shift_toggle,compose:caps",

        follow_mouse = 1,
        sensitivity  = 0,

        repeat_rate  = 40,
        repeat_delay = 250,

        numlock_by_default = true,

        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            clickfinger_behavior = true,
            scroll_factor        = 0.5,
        },
    },
})

-- Touchpad gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
