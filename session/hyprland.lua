-- Tessarchy defaults: Hyprland 0.56.x Lua API.
-- This is loaded explicitly, never over the user's Hyprland config.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.config({
    general = { gaps_in = 0, gaps_out = 0, border_size = 0, layout = "dwindle" },
    decoration = { rounding = 18, blur = { enabled = false }, shadow = { enabled = false } },
    animations = { enabled = false },
    input = { kb_layout = "us", follow_mouse = 0 },
    misc = { disable_hyprland_logo = true, force_default_wallpaper = 0 },
})
-- Read the same saved mode as Tessera when a new ordinary app opens.
-- Existing windows and floating dialogs are left alone when modes change.
local function shell_mode(monitor)
    local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
    local file = io.open(config .. "/tessarchy/shell.ini", "r")
    local mode, section = "auto", ""
    if file then
        for line in file:lines() do
            section = line:match("^%[([^%]]+)%]%s*$") or section
            if section == "Shell" then
                mode = line:match("^%s*layoutMode%s*=%s*(%a+)%s*$") or mode
            end
        end
        file:close()
    end
    if mode == "phone" or mode == "tablet" or mode == "desktop" then return mode end
    local width, height = monitor.width / monitor.scale, monitor.height / monitor.scale
    if monitor.transform % 2 == 1 then width, height = height, width end
    if math.min(width, height) < 600 then return "phone" end
    if width >= 1100 and height >= 650 then return "desktop" end
    return "tablet"
end
hl.on("window.open", function(window)
    if window.floating or window.fullscreen ~= 0 or not window.monitor then return end
    if shell_mode(window.monitor) ~= "desktop" then
        hl.dispatch(hl.dsp.window.fullscreen({ window = window, mode = "maximized", action = "set" }))
    end
end)
hl.on("hyprland.start", function ()
    hl.exec_cmd("tessera-shell")
    -- Blank the panel after five minutes of inactivity; any input wakes it.
    -- hypridle respects idle inhibitors, and no lock command is configured.
    local share = os.getenv("TESSARCHY_DATA_DIR") or "/usr/share/tessarchy"
    hl.exec_cmd('hypridle -c "' .. share .. '/session/hypridle.conf" &')
end)
hl.bind("SUPER + Return", hl.dsp.exec_cmd("foot"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("tessera-shell"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())
-- Desktop mode: numbered workspaces, directional focus and window moving.
-- These bindings are harmless in the touch layouts and mirror the workspace
-- strip in the status bar.
for i = 1, 5 do
    local key = tostring(i)
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + Tab", hl.dsp.window.cycle_next())
hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- Volume keys mirror the Tessera controls page when PipeWire is running.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
-- Full-screen capture through the shipped helper; it notifies on success.
hl.bind("Print", hl.dsp.exec_cmd("tessera-screenshot"))
-- Brightness keys use the shipped helper; it is silent without a backlight.
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("tessera-brightness up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("tessera-brightness down"), { locked = true, repeating = true })
-- Preferences are user-owned, never installed over existing files.
local home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local preferences = home .. "/tessarchy/preferences.lua"
local f = io.open(preferences, "r")
if f then f:close(); dofile(preferences) end
