local ADDON_NAME, core = ...;

core.config = core.GetConfig()

core.barToRuneIndex = {
    1, -- Blood Rune
    2, -- Blood Rune
    5, -- Frost Rune
    6, -- Frost Rune
    3, -- Unholy Rune
    4, -- Unholy Rune
}
core.runeToBarIndex = {}
for i = 1, 6 do
    core.runeToBarIndex[i] = core.barToRuneIndex[i]
end


core.SplitString = function(input, delimiter)
    local result = {}
    for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end


core.print_table = function(table, prefix)

    for k, v in pairs(table) do
        if type(v) == "table" then
            if not prefix then prefix = "  " end
            print(prefix .. k .. ":")
            core.print_table(v, prefix .. "  ")
        elseif prefix then
            print(prefix, k, v)
        else
            print(k, v)
        end
    end
end

local CreateBar = function(bar_index)
    local bar = CreateFrame("StatusBar", "RuneBar_" .. bar_index, core.frame)
    bar.bar_index = bar_index
    bar.rune_index = core.barToRuneIndex[bar_index]

    bar:SetSize(core.config.BAR_WIDTH, core.config.BAR_HEIGHT)
    bar:SetStatusBarTexture("Interface/Addons/DeathKnightRunes/media/statusbar/bar_background.tga")
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:GetStatusBarTexture():SetVertTile(false)
    bar:SetMinMaxValues(0, 8.33)  -- Rune regen will be around 8.33 seconds at most
    bar:SetValue(8.33) -- Set the initial bar to be full

     -- Set the position of the bar
    local group = math.floor((bar.bar_index - 1) / 2)
    local rang = (bar.bar_index - 1) % 2
    local x_offset = (bar.bar_index - 1) * core.config.BAR_WIDTH + group * core.config.GAP_BETWEEN_GROUPS + (rang + group) * core.config.GAP_INSIDE_GROUP
    bar:SetPoint("LEFT", core.frame, "LEFT", x_offset, 0)

    -- Create a Background for the bar
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints(true)
    bar.bg:SetColorTexture(0, 0, 0, core.config.BACKGROUND_ALPHA)

    -- Create a border around the bar
    if core.config.BORDER_THICKNESS > 0 then
        bar.border = CreateFrame("Frame", nil, bar, BackdropTemplateMixin and "BackdropTemplate")
        bar.border:SetPoint("TOPLEFT", -core.config.BORDER_THICKNESS, core.config.BORDER_THICKNESS)
        bar.border:SetPoint("BOTTOMRIGHT", core.config.BORDER_THICKNESS, -core.config.BORDER_THICKNESS)
        bar.border:SetBackdrop({
            edgeFile = "Interface/CharacterFrame/UI-Party-Border",  -- A standard thin border texture
            edgeSize = core.config.BORDER_THICKNESS,
        })
        bar.border:SetBackdropBorderColor(1, 1, 1)  -- White border color; adjust as needed
    end

    -- Text for the bar
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.text:SetFont("Fonts/FRIZQT__.TTF", core.config.TEXT_CD_SIZE, "OUTLINE")
    bar.text:SetTextColor(1, 1, 1)
    bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar.text:SetJustifyH("CENTER")

    bar.SetRuneColor = function(self)
        local rune_type = GetRuneType(self.rune_index)

        local color = core.config.BLOOD_RUNE_COLOR  -- Blood Runes: Red
        if rune_type == 2 then
            color = core.config.FROST_RUNE_COLOR  -- Frost Runes: Blue
        elseif rune_type == 3 then
            color = core.config.UNHOLY_RUNE_COLOR  -- Unholy Runes: Green
        elseif rune_type == 4 then
            color = core.config.DEATH_RUNE_COLOR  -- Death Runes: Purple
        end
        bar:SetStatusBarColor(unpack(color))
    end

    bar.UpdateBar = function(self, start, rune_cd, rune_ready)

        local now = GetTime()
        self.start = start
        self.rune_cd = rune_cd
        self.progress = now - start
        self.remaining_time = rune_cd - self.progress
        self.text_str = string.format("%.01f", self.remaining_time)

        self:SetMinMaxValues(0, rune_cd)
        self:SetValue(self.progress)
        self.text:SetText(self.text_str)

        self:SetRuneColor()
    end

    bar:SetScript("OnUpdate", function(self, elapsed)
        local rune_cd = self.rune_cd

        if not rune_cd then return end
        if self.start == 0 then
            self:SetMinMaxValues(0, rune_cd)
            self:SetValue(rune_cd)
            self.text:SetText("")
        end

        local now = GetTime()
        local progress = now - self.start
        local remaining_time = rune_cd - progress
        local text_str = string.format("%.01f", remaining_time)

        if remaining_time <= 0 then
            progress = rune_cd
            text_str = ""
        end

        self:SetMinMaxValues(0, rune_cd)
        self:SetValue(progress)
        self.text:SetText(text_str)
        self:SetRuneColor()
    end)

    return bar
end

local CreateRunesFrame = function()

    core.frame = CreateFrame("Frame", "DeathStrikeRunesFrame", UIParent)
    local frame = core.frame
    -- Set the position of the frame
    --frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", core.config.FRAME_X or 0, core.config.FRAME_Y or 0)
    frame:SetAlpha(core.config.OUT_OF_COMBAT_ALPHA)
    frame:SetSize(core.config.TOTAL_WIDTH, core.config.TOTAL_HEIGHT)

    frame.bars = {}
    for bar_index = 1, 6 do
        frame.bars[bar_index] = CreateBar(bar_index)
    end

    frame.UpdateBar = function(self, bar_index)
        local rune_index = core.barToRuneIndex[bar_index]
        local start, rune_cd, rune_ready = GetRuneCooldown(rune_index)
        local bar = frame.bars[bar_index]
        bar:UpdateBar(start, rune_cd, rune_ready)
    end

    -- Updates the type and CD of all runes
    frame.UpdateAllBars = function(self)
        for bar_index = 1, 6 do
            frame:UpdateBar(bar_index)
        end
    end

    -- Event handler for tracking runes
    frame:SetScript("OnEvent", function(self, event, rune_index, ...)

        local bar_index = core.runeToBarIndex[rune_index]

        if event == "RUNE_POWER_UPDATE" then
            if bar_index then
                frame:UpdateBar(bar_index)
            end

        elseif event == "RUNE_TYPE_UPDATE" then
            if bar_index then
                frame.bars[bar_index]:SetRuneColor()
            end

        elseif event == "PLAYER_REGEN_ENABLED" then
            frame:SetAlpha(core.config.OUT_OF_COMBAT_ALPHA)

        elseif event == "PLAYER_REGEN_DISABLED" then
            frame:SetAlpha(core.config.IN_COMBAT_ALPHA)

        elseif event == "PLAYER_ENTERING_WORLD" then
            frame:UpdateAllBars()
        end

        return true
    end)

    -- Update each rune with the current values
    frame:SetScript("OnShow", function()
        frame:UpdateAllBars()
    end)

    -- Drag functionality
    frame:SetScript("OnDragStart", function(self)

        print(core.GetConfigValue("LOCK_FRAME") )
        if core.GetConfigValue("LOCK_FRAME") then
            return
        end

        frame:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        
        self:StopMovingOrSizing()

        if core.GetConfigValue("LOCK_FRAME") then
            return
        end

        -- Get current position
        local point, _, relativePoint, xOffset, yOffset = self:GetPoint()

        -- Re-anchor to UIParent explicitly
        self:ClearAllPoints()
        self:SetPoint(point, UIParent, relativePoint, xOffset, yOffset)

        -- Save position
        RunesDB.FRAME_X = xOffset
        RunesDB.FRAME_Y = yOffset

    end)

    -- Register events to track runes
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("RUNE_TYPE_UPDATE")
    frame:RegisterEvent("RUNE_POWER_UPDATE")
end


local _, class_id = UnitClassBase("player");
if class_id == 6 then
    CreateRunesFrame()
end
