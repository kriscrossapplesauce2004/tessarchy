-- Tessarchy defaults: Hyprland 0.56.x Lua API.
-- This is loaded explicitly, never over the user's Hyprland config.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.config({
    general = { gaps_in = 0, gaps_out = 0, border_size = 0, layout = "dwindle" },
    decoration = { rounding = 18, blur = { enabled = true, size = 4, passes = 2 }, shadow = { enabled = false } },
    animations = { enabled = false },
    input = { kb_layout = "us", follow_mouse = 0 },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true, force_default_wallpaper = 0 },
})
-- Frost only Tessera glass surfaces; leave applications unchanged.
hl.layer_rule({ match = { namespace = "tessera(-status)?" }, blur = true, ignore_alpha = 0.01 })
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
-- Re-maximize ordinary mobile windows when they become active.
local function maximize_if_mobile(window)
    if not window or window.floating or window.fullscreen ~= 0 or not window.monitor then return end
    if shell_mode(window.monitor) ~= "desktop" then
        hl.dispatch(hl.dsp.window.fullscreen({ window = window, mode = "maximized", action = "set" }))
    end
end
-- Request usable dimensions while respecting application minimum sizes.
local function fit_dialog(window)
    if not window or not window.floating or window.fullscreen ~= 0 or not window.monitor then return end
    local size = window.size
    if type(size) ~= "table" or not size.x or not size.y then return end
    local monitor = window.monitor
    if shell_mode(monitor) == "desktop" then return end
    local width, height = monitor.width / monitor.scale, monitor.height / monitor.scale
    if monitor.transform % 2 == 1 then width, height = height, width end
    local reserved = type(monitor.reserved) == "table" and monitor.reserved or {}
    width = math.max(1, math.floor(width - (reserved.left or 0) - (reserved.right or 0)))
    height = math.max(1, math.floor(height - (reserved.top or 0) - (reserved.bottom or 0)))
    if size.x <= width and size.y <= height then return end
    hl.dispatch(hl.dsp.window.resize({ window = window, x = math.min(size.x, width), y = math.min(size.y, height) }))
    hl.dispatch(hl.dsp.window.center({ window = window }))
end
hl.on("window.open", function(window)
    maximize_if_mobile(window)
    fit_dialog(window)
end)
hl.on("window.active", maximize_if_mobile)
hl.on("hyprland.start", function ()
    hl.exec_cmd("tessera-shell")
    -- Optional; exits quietly when squeekboard is not installed.
    hl.exec_cmd("tessarchy-osk start")
end)
-- Same card switcher for touch and keyboard. Alt release commits selection.
-- Keycodes 64/108 are left/right Alt in the configured evdev/US keymap.
-- These bindings remain available while the switcher has an exclusive layer grab.
hl.bind("ALT + Tab", hl.dsp.exec_cmd("tessera-shell ipc call switcher next"), { locked = true })
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("tessera-shell ipc call switcher previous"), { locked = true })
hl.bind("code:64", hl.dsp.exec_cmd("tessera-shell ipc call switcher accept"), { release = true, ignore_mods = true, locked = true })
hl.bind("code:108", hl.dsp.exec_cmd("tessera-shell ipc call switcher accept"), { release = true, ignore_mods = true, locked = true })
hl.bind("Print", hl.dsp.exec_cmd("tessera-screenshot"))
hl.bind("SUPER + Return", hl.dsp.exec_cmd("foot"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("tessera-shell"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("tessera-shell ipc call actions endSession"))
-- Desktop mode: numbered workspaces, directional focus and window moving.
-- These bindings are harmless in the touch layouts and mirror the workspace
-- strip in the status bar.
for i = 1, 5 do
    local key = tostring(i)
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind("SUPER + Q", hl.dsp.exec_cmd("tessera-shell ipc call actions closeWindow"))
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
-- Preferences are user-owned, never installed over existing files.
local home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local preferences = home .. "/tessarchy/preferences.lua"
local f = io.open(preferences, "r")
if f then f:close(); dofile(preferences) end
