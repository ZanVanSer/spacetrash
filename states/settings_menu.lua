local Settings = require("systems/settings")
local Menu = require("ui/menu")
local Colors = require("ui/colors")
local Fonts = require("ui/fonts")
local Screen = require("systems/screen")
local sm = require("states/statemanager")

local SettingsMenu = {}

function SettingsMenu:enter()
    self.currentSettings = Settings.load()
    self.originalSettings = Settings.load() -- Backup for comparison
    self.needsApply = false
    self.saveMessageTimer = 0
    
    -- Structure defining the settings layout and options
    self.sections = {
        {
            name = "Video",
            options = {
                { name = "Resolution", key = "resolution", category = "video", values = {"800x600", "1280x720", "1920x1080", "Fullscreen"} },
                { name = "Fullscreen", key = "fullscreen", category = "video", values = {true, false} },
                { name = "VSync", key = "vsync", category = "video", values = {true, false} }
            }
        },
        {
            name = "Audio",
            options = {
                { name = "Master Volume", key = "masterVolume", category = "audio", isSlider = true },
                { name = "Music Volume", key = "musicVolume", category = "audio", isSlider = true },
                { name = "SFX Volume", key = "sfxVolume", category = "audio", isSlider = true }
            }
        },
        {
            name = "Gameplay",
            options = {
                { name = "Screen Shake", key = "screenShake", category = "gameplay", values = {true, false} },
                { name = "Particles", key = "particles", category = "gameplay", values = {true, false} }
            }
        }
    }

    self.selectedSection = 1
    self.selectionRow = 0 -- 0: Tabs, 1-N: Options, N+1: Back
    self.selectedOption = 1
    
    self.showConfirm = false
    self.confirmOptions = {"Apply", "Discard", "Cancel"}
    self.confirmSelection = 1
    
    self.isResetting = false
end

function SettingsMenu:update(dt)
    if self.saveMessageTimer > 0 then
        self.saveMessageTimer = self.saveMessageTimer - dt
    end
end

function SettingsMenu:checkDifferences()
    -- Check if any setting differs from original
    for _, section in ipairs(self.sections) do
        for _, opt in ipairs(section.options) do
            if self.currentSettings[opt.category][opt.key] ~= self.originalSettings[opt.category][opt.key] then
                return true
            end
        end
    end
    return false
end

function SettingsMenu:syncOriginal()
    -- Create a deep copy of current settings into original
    self.originalSettings = Settings.load() -- Simplest way since we just saved it
end

function SettingsMenu:keypressed(key)
    if self.isResetting then
        if key == "y" then
            self.currentSettings = Settings.getDefaults()
            Settings.save(self.currentSettings)
            Settings.apply(self.currentSettings)
            self:syncOriginal()
            self.needsApply = false
            self.isResetting = false
            self.saveMessageTimer = 2.0
        elseif key == "n" or key == "x" or key == "escape" then
            self.isResetting = false
        end
        return
    end

    if self.showConfirm then
        if key == "up" then
            self.confirmSelection = self.confirmSelection - 1
            if self.confirmSelection < 1 then self.confirmSelection = #self.confirmOptions end
        elseif key == "down" then
            self.confirmSelection = self.confirmSelection + 1
            if self.confirmSelection > #self.confirmOptions then self.confirmSelection = 1 end
        elseif key == "z" or key == "return" then
            if self.confirmSelection == 1 then -- Apply
                Settings.save(self.currentSettings)
                Settings.apply(self.currentSettings)
                self:syncOriginal()
                sm.switch("main_menu")
            elseif self.confirmSelection == 2 then -- Discard
                sm.switch("main_menu")
            elseif self.confirmSelection == 3 then -- Cancel
                self.showConfirm = false
            end
        elseif key == "x" or key == "escape" then
            self.showConfirm = false
        end
        return
    end

    if key == "r" then
        self.isResetting = true
        return
    end

    local section = self.sections[self.selectedSection]
    local numOptions = #section.options

    if key == "up" then
        self.selectionRow = self.selectionRow - 1
        if self.selectionRow < 0 then
            self.selectionRow = numOptions + 1
        end
    elseif key == "down" then
        self.selectionRow = self.selectionRow + 1
        if self.selectionRow > numOptions + 1 then
            self.selectionRow = 0
        end
    elseif key == "left" then
        if self.selectionRow == 0 or self.selectionRow == numOptions + 1 then
            self.selectedSection = self.selectedSection - 1
            if self.selectedSection < 1 then self.selectedSection = #self.sections end
        else
            self.selectedOption = self.selectionRow
            self:changeValue(-1)
        end
    elseif key == "right" then
        if self.selectionRow == 0 or self.selectionRow == numOptions + 1 then
            self.selectedSection = self.selectedSection + 1
            if self.selectedSection > #self.sections then self.selectedSection = 1 end
        else
            self.selectedOption = self.selectionRow
            self:changeValue(1)
        end
    elseif key == "z" or key == "return" then
        if self.selectionRow == numOptions + 1 then
            if self.needsApply then
                self.showConfirm = true
                self.confirmSelection = 1
            else
                sm.switch("main_menu")
            end
        else
            -- Quick apply for individual options if on Z
            local success = Settings.save(self.currentSettings)
            Settings.apply(self.currentSettings)
            self:syncOriginal()
            self.needsApply = false
            if success then
                self.saveMessageTimer = 2.0
            end
        end
    elseif key == "x" or key == "escape" then
        if self.needsApply then
            self.showConfirm = true
            self.confirmSelection = 1
        else
            sm.switch("main_menu")
        end
    end
end

function SettingsMenu:changeValue(dir)
    local section = self.sections[self.selectedSection]
    local option = section.options[self.selectionRow] -- Use selectionRow here for correct option indexing
    if not option then return end
    
    local currentVal = self.currentSettings[option.category][option.key]

    if option.isSlider then
        local newVal = currentVal + (dir * 0.1)
        newVal = math.floor(newVal * 10 + 0.5) / 10
        self.currentSettings[option.category][option.key] = math.max(0, math.min(1, newVal))
    elseif option.values then
        local idx = 1
        for i, v in ipairs(option.values) do
            if v == currentVal then idx = i break end
        end
        idx = idx + dir
        if idx < 1 then idx = #option.values
        elseif idx > #option.values then idx = 1 end
        self.currentSettings[option.category][option.key] = option.values[idx]
    end
    
    self.needsApply = self:checkDifferences()
end

function SettingsMenu:draw()
    Screen.applyScale()
    
    local vw, vh = Screen.getVirtualWidth(), Screen.getVirtualHeight()
    local section = self.sections[self.selectedSection]
    local numOptions = #section.options
    
    -- Title
    love.graphics.setFont(Fonts.getFont("huge"))
    Colors.setColor("accent")
    love.graphics.printf("SETTINGS", 0, 50, vw, "center")

    -- Tabs / Sections
    love.graphics.setFont(Fonts.getFont("large"))
    local sectionWidth = vw / #self.sections
    for i, s in ipairs(self.sections) do
        local x = (i - 1) * sectionWidth
        local isCurrentSection = (i == self.selectedSection)
        local isTabsSelected = (self.selectionRow == 0)
        
        if isCurrentSection then
            if isTabsSelected then
                Colors.setColor("accent")
                love.graphics.rectangle("line", x + 10, 100, sectionWidth - 20, 40)
            else
                Colors.setColor("accent", 0.5)
                love.graphics.rectangle("line", x + 10, 100, sectionWidth - 20, 40)
            end
            Colors.setColor("accent")
        else
            Colors.setColor("dim")
        end
        love.graphics.printf(s.name, x, 110, sectionWidth, "center")
    end

    -- Options
    local optionsY = 180
    love.graphics.setFont(Fonts.getFont("normal"))

    for i, option in ipairs(section.options) do
        local isRowSelected = (self.selectionRow == i)
        local y = optionsY + (i - 1) * 40
        
        local val = self.currentSettings[option.category][option.key]
        local isModified = (val ~= self.originalSettings[option.category][option.key])
        local valText = ""
        
        if option.isSlider then
            local percent = math.floor(val * 100 + 0.5)
            local bars = math.floor(percent / 10)
            local barText = "[" .. string.rep("=", bars) .. string.rep("-", 10 - bars) .. "]"
            valText = string.format("%s %d%%", barText, percent)
        else
            local displayVal = tostring(val)
            if displayVal == "true" then displayVal = "ON"
            elseif displayVal == "false" then displayVal = "OFF"
            end
            valText = "< " .. displayVal .. " >"
        end

        -- Modified indicator
        if isModified then
            Colors.setColor("danger")
            love.graphics.print("*", 80, y)
        end

        if option.category == "gameplay" then
            local displayVal = (val == true and "ON" or "OFF")
            local fullText = "< " .. option.name .. ": " .. displayVal .. " >"
            if isRowSelected then
                Colors.setColor("accent")
                love.graphics.printf(fullText, 0, y, vw, "center")
            else
                Colors.setColor(isModified and "danger" or "white")
                love.graphics.printf(option.name .. ": " .. displayVal, 0, y, vw, "center")
            end
        else
            if isRowSelected then
                Colors.setColor("accent")
                love.graphics.print("> " .. option.name, 100, y)
            else
                Colors.setColor(isModified and "danger" or "white")
                love.graphics.print(option.name, 120, y)
            end
            love.graphics.printf(valText, 400, y, vw - 500, "right")
        end
    end

    -- Save/Apply Messages
    if self.saveMessageTimer > 0 then
        Colors.setColor("accent", math.min(1, self.saveMessageTimer))
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.printf("Settings saved!", 0, vh - 140, vw, "center")
    elseif self.needsApply then
        Colors.setColor("danger")
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.printf("Unsaved changes! Press [Z] to save all.", 0, vh - 140, vw, "center")
    end

    -- Back button
    local backY = vh - 100
    if self.selectionRow == numOptions + 1 then
        Colors.setColor("accent")
        love.graphics.printf("> BACK TO MENU <", 0, backY, vw, "center")
    else
        Colors.setColor("white")
        love.graphics.printf("BACK TO MENU", 0, backY, vw, "center")
    end

    -- Overlays
    if self.showConfirm or self.isResetting then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, vw, vh)
        
        local boxW, boxH = 400, 250
        local bx, by = (vw - boxW) / 2, (vh - boxH) / 2
        love.graphics.setColor(0.1, 0.1, 0.15, 1)
        love.graphics.rectangle("fill", bx, by, boxW, boxH)
        Colors.setColor("accent")
        love.graphics.rectangle("line", bx, by, boxW, boxH)
        
        if self.isResetting then
            love.graphics.setFont(Fonts.getFont("large"))
            love.graphics.printf("Reset all settings?", bx, by + 50, boxW, "center")
            love.graphics.setFont(Fonts.getFont("normal"))
            love.graphics.printf("Press [Y] to confirm\nPress [N] to cancel", bx, by + 120, boxW, "center")
        else
            love.graphics.setFont(Fonts.getFont("large"))
            love.graphics.printf("Apply Changes?", bx, by + 30, boxW, "center")
            love.graphics.setFont(Fonts.getFont("normal"))
            for i, opt in ipairs(self.confirmOptions) do
                local optY = by + 100 + (i - 1) * 40
                if i == self.confirmSelection then
                    Colors.setColor("accent")
                    love.graphics.printf("> " .. opt .. " <", bx, optY, boxW, "center")
                else
                    Colors.setColor("white")
                    love.graphics.printf(opt, bx, optY, boxW, "center")
                end
            end
        end
    end

    -- Controls help
    if not (self.showConfirm or self.isResetting) then
        love.graphics.setFont(Fonts.getFont("small"))
        Colors.setColor("dim")
        love.graphics.printf("UP/DOWN: Navigate | LEFT/RIGHT: Change | Z: Save | R: Reset Defaults", 0, vh - 40, vw, "center")
    end

    Screen.removeScale()
end

return SettingsMenu
