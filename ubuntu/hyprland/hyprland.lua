local var_mod = "SUPER"
local var_terminal = "kitty"
local var_menu = "noctalia msg panel-toggle launcher"

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
    general = {
        gaps_in = 4,
        gaps_out = 10,
        border_size = 1,
        col = {
            active_border = "rgba(7aa2f7ff)",
            inactive_border = "rgba(232833ff)",
        },
        layout = "dwindle",
    },
    dwindle = {
        preserve_split = true,
    },
    decoration = {
        rounding = 10,
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            noise = 0.02,
        },
        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = "rgba(00000066)",
        },
    },
    animations = {
        enabled = true,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
        },
    },
})

require("monitors")
hl.env("XCURSOR_SIZE", "24")
hl.env("GDK_SCALE", "2")
hl.curve("smooth", { type = "bezier", points = { {0.25, 0.8}, {0.25, 1} } })
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4,
    bezier = "smooth",
    style = "popin 92%",
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 4,
    bezier = "smooth",
})
hl.animation({
    leaf = "workspaces",
    enabled = false,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("/usr/libexec/hyprpolkitagent")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("noctalia --daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- macOS-style Spaces: 4-finger horizontal swipe slides between whole workspaces
hl.config({
    misc = {
        disable_hyprland_logo = true,
        background_color = "rgb(0b0d12)",
    },
})

hl.gesture({
    fingers = 4,
    direction = "horizontal",
    action = "workspace",
})
hl.bind(var_mod .. " + Return", hl.dsp.exec_cmd(var_terminal))
hl.bind(var_mod .. " + D", hl.dsp.exec_cmd(var_menu))
hl.bind(var_mod .. " + SPACE", hl.dsp.exec_cmd(var_menu))

-- tap Super alone (fires on release) to toggle the Noctalia launcher
hl.bind(var_mod .. " + SUPER_L", hl.dsp.exec_cmd(var_menu), {
    release = true,
})
hl.bind(var_mod .. " + S", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(var_mod .. " + comma", hl.dsp.exec_cmd("noctalia msg settings-toggle"))
hl.bind(var_mod .. " + Q", hl.dsp.window.close())
hl.bind(var_mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(var_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(var_mod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(var_mod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(var_mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(var_mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(var_mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(var_mod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch whole spaces (same keys as GNOME)
hl.bind("CTRL + ALT + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("CTRL + ALT + left", hl.dsp.focus({ workspace = "e-1" }))

-- Move the focused window to the next/previous space
hl.bind("CTRL + ALT + SHIFT + right", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("CTRL + ALT + SHIFT + left", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(var_mod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(var_mod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(var_mod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(var_mod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(var_mod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(var_mod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(var_mod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(var_mod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(var_mod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(var_mod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(var_mod .. " + mouse:272", hl.dsp.window.drag(), {
    mouse = true,
})
hl.bind(var_mod .. " + mouse:273", hl.dsp.window.resize(), {
    mouse = true,
})
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"))
hl.bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(var_mod .. " + C", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
hl.bind(var_mod .. " + P", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(var_mod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(var_mod .. " + B", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(var_mod .. " + A", hl.dsp.exec_cmd("pavucontrol"))

-- More spaces
hl.bind(var_mod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(var_mod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(var_mod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(var_mod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(var_mod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(var_mod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(var_mod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(var_mod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(var_mod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(var_mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- New space: jump to the first empty workspace, optionally carrying the focused window
hl.bind(var_mod .. " + N", hl.dsp.focus({ workspace = "empty" }))
hl.bind(var_mod .. " + SHIFT + N", hl.dsp.window.move({ workspace = "empty" }))

-- Overview (hyprexpo): Mission Control style grid of spaces. Click a space to go there,
-- drag a window from one space onto another to move it. Toggle with Super+Tab or a 4-finger swipe up.
hl.plugin.load("/home/devniel/.local/lib/hyprexpo/hyprexpo.so")

hl.config({
    plugin = {
        hyprexpo = {
            columns = 3,
            gaps_in = 8,
            bg_col = "rgb(0b0d12)",
            workspace_method = "center current",
            drag_drop_enable = 1,
        },
    },
})

hl.bind(var_mod .. " + TAB", function()
    hl.plugin.hyprexpo.expo("toggle")
end)
hl.gesture({
    fingers = 4,
    direction = "up",
    action = function()
        hl.plugin.hyprexpo.expo("toggle")
    end,
})

-- Noctalia: blur its surfaces, use its own animations, float the settings window
hl.layer_rule({
    match = {
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
    },
    no_anim = true,
})
hl.layer_rule({
    match = {
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
    },
    blur = true,
})
hl.layer_rule({
    match = {
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
    },
    blur_popups = true,
})
hl.layer_rule({
    match = {
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
    },
    ignore_alpha = 0.5,
})
hl.window_rule({
    match = {
        class = "^dev\\.noctalia\\.Noctalia$",
    },
    float = true,
})
hl.window_rule({
    match = {
        class = "^dev\\.noctalia\\.Noctalia$",
    },
    size = "1080 920",
})

-- HyprMod managed settings
require("hyprland-gui")
