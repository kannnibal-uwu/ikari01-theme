-- vim: ft=lua
-- Ikari-01 theme for Rex
-- Scheme Author: kannnibal
-- Scheme System: base24
-- Template Author: Tinted Terminal (https://github.com/tinted-theming/tinted-terminal)
--
-- Imports this scheme into every Rex app running on this machine and switches
-- the app to the scheme's appearance. Run it with the Rex CLI, for example as a
-- tinty hook:
--
--     hook = "rex --autostart=false do %f"
--
-- Rex can only import theme files from the app's own machine, so apps connected
-- to the Rex server from another machine are skipped. Run tinty there too.

local name = "base24-ikari01"
local variant = "darklight"

-- This must match themes/ghostty/base24-ikari01 exactly. CI checks that it does.
local theme = [==[
# vim: ft=ghostty
# Ikari-01 theme for Ghostty
# Scheme Author: kannnibal
# Scheme System: base24
# Template Author: Tinted Terminal (https://github.com/tinted-theming/tinted-terminal)

# Color palette
palette = 0=#1d1a2f
palette = 1=#be5e13
palette = 2=#319742
palette = 3=#c79128
palette = 4=#61a5ff
palette = 5=#e14dff
palette = 6=#3cd3a0
palette = 7=#dac2ff
palette = 8=#5a4984
palette = 9=#be5e13
palette = 10=#319742
palette = 11=#c79128
palette = 12=#61a5ff
palette = 13=#e14dff
palette = 14=#3cd3a0
palette = 15=#e3d1ff
palette = 16=#984d14
palette = 17=#4c3b77
palette = 18=#342455
palette = 19=#3e2c64
palette = 20=#68578b
palette = 21=#f2e5ff

# Foreground & background colors
background = #1d1a2f
foreground = #dac2ff
cursor-color = #dac2ff
selection-background = #dac2ff
selection-foreground = #3e2c64
search-background = #c79128
search-foreground = #342455e3d1ff
search-selected-background = #984d14
search-selected-foreground = #342455e3d1ff

# Set `macos-icon = custom-style` in your main configuration file to enable theming of the app icon.
#
# Set the ghost color to the lightest foreground:
macos-icon-ghost-color = #e3d1ff
# Replace the official icon's blue background with the designated bright blue color:
macos-icon-screen-color = #61a5ff
]==]

local me = assert(rex.call("server.whoami")).principal
if me.transport ~= "unix" then
    io.stderr:write("rex: not connected to a local Rex server, skipping\n")
    return
end

-- Rex names an imported theme after its file, and re-importing a name
-- replaces that theme's colors.
local home = os.getenv("HOME")
local dir = (os.getenv("XDG_CACHE_HOME") or (home .. "/.cache")) .. "/tinted-theming/rex"
rex.exec({ "mkdir", "-p", dir })
local file = dir .. "/" .. name
local out = assert(io.open(file, "w"))
out:write(theme)
out:close()

local function perform(client, action, args)
    local _, err = rex.call("client.perform", {
        client_id = client.client_id, action = action, args = args,
    })
    return err
end

-- Apps connected over the server's local socket as the same user are the
-- apps on this machine.
local list = assert(rex.call("client.list", { kinds = { "app" } }))
local failures = {}
for _, client in ipairs(list.clients or {}) do
    local peer = client.principal or {}
    local label = (client.info or {}).label or client.client_id
    if peer.transport == "unix" and peer.uid == me.uid then
        -- Rex guesses a theme's appearance from its colors when importing.
        -- Switch to the scheme's own variant in case it guessed wrong.
        local err = perform(client, "client.theme.import", { path = file })
            or perform(client, "client.appearance.switch_mode", { mode = variant })
        if err then
            table.insert(failures, label .. ": " .. tostring(err))
        end
    else
        io.stderr:write("rex: skipped " .. label .. ", which is connected from another machine or user\n")
    end
end

if #failures > 0 then
    error(table.concat(failures, "\n"))
end
