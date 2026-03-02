local json = require("systems/json")
local Screenshake = require("systems/screenshake")
local Particles = require("systems/particles")

local Settings = {}

local SETTINGS_FILE = "settings.json"

--- Returns the default settings structure.
function Settings.getDefaults()
    return {
        video = {
            resolution = "1280x720",
            vsync = true,
            fullscreen = false
        },
        audio = {
            masterVolume = 1.0,
            musicVolume = 0.8,
            sfxVolume = 0.8
        },
        gameplay = {
            screenShake = true,
            particles = true
        }
    }
end

--- Loads settings from the settings.json file or returns defaults.
function Settings.load()
    if love.filesystem.getInfo(SETTINGS_FILE) then
        local content, size = love.filesystem.read(SETTINGS_FILE)
        if content then
            local success, data = pcall(json.decode, content)
            if success and data then
                -- Merge with defaults to ensure all keys exist
                local settings = Settings.getDefaults()
                for category, values in pairs(data) do
                    if type(values) == "table" and settings[category] then
                        for k, v in pairs(values) do
                            settings[category][k] = v
                        end
                    end
                end
                return settings
            end
        end
    end
    return Settings.getDefaults()
end

--- Saves the provided settings to settings.json.
function Settings.save(settings)
    local success, content = pcall(json.encode, settings)
    if not success then
        print("WARNING: Failed to encode settings to JSON")
        return false
    end
    
    local ok, err = love.filesystem.write(SETTINGS_FILE, content)
    if not ok then
        print("WARNING: Failed to write settings file: " .. tostring(err))
        return false
    end
    
    return true
end

--- Applies the settings to the game engine.
function Settings.apply(settings)
    -- 1. Video Settings
    local targetWidth, targetHeight
    -- Normalize targetFullscreen: Resolution list takes precedence if set to "Fullscreen"
    local targetFullscreen = (settings.video.resolution == "Fullscreen") or (settings.video.fullscreen == true)
    local targetVSync = (settings.video.vsync == true or settings.video.vsync == 1)
    
    if settings.video.resolution == "Fullscreen" then
        local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
        targetWidth, targetHeight = desktopWidth, desktopHeight
    else
        -- Parse "800x600" format
        local w, h = settings.video.resolution:match("(%d+)x(%d+)")
        targetWidth = tonumber(w) or 800
        targetHeight = tonumber(h) or 600
    end

    local currentWidth, currentHeight, currentFlags = love.window.getMode()
    
    -- Normalize current flags for comparison (LÖVE vsync can be 1, 0, -1 or true/false)
    local currentVSync = (currentFlags.vsync == true or currentFlags.vsync == 1)
    local currentFullscreen = (currentFlags.fullscreen == true)

    -- Only update window mode if settings have actually changed
    if currentWidth ~= targetWidth or 
       currentHeight ~= targetHeight or 
       currentFullscreen ~= targetFullscreen or 
       currentVSync ~= targetVSync then
        
        local success = pcall(function()
            love.window.setMode(targetWidth, targetHeight, {
                fullscreen = targetFullscreen,
                vsync = targetVSync,
                resizable = true
            })
        end)
        
        if not success then
            print("ERROR: Failed to set window mode: " .. tostring(targetWidth) .. "x" .. tostring(targetHeight))
            love.window.setMode(800, 600, { fullscreen = false, vsync = true, resizable = true })
        end
    end

    -- 2. Audio Settings
    love.audio.setVolume(settings.audio.masterVolume or 1.0)
    
    -- 3. Gameplay Settings
    Screenshake.enabled = settings.gameplay.screenShake
    Particles.enabled = settings.gameplay.particles
end

return Settings
