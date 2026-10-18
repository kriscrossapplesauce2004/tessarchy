-- Isolated pre-login compositor; never loads the user's session/preferences.
hl.monitor({ output = os.getenv("TESSARCHY_GREETER_OUTPUT") or "",
    mode = os.getenv("TESSARCHY_GREETER_MODE") or "preferred", position = "auto", scale = 1 })
hl.config({
    general = { gaps_in = 0, gaps_out = 0, border_size = 0 },
    decoration = { rounding = 0, shadow = { enabled = false } },
    animations = { enabled = false },
    input = { kb_layout = "us", follow_mouse = 0 },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true, force_default_wallpaper = 0 },
})
hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/bin/tessarchy-greeter")
end)
