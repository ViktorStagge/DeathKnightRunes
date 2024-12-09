local ADDON_NAME, core = ...;

core.config = {
    BACKGROUND_ALPHA = 0.6,
    TEXT_CD_SIZE = 12,
    BAR_WIDTH = 35,
    BAR_HEIGHT = 20,
    BORDER_THICKNESS = 0,
    GAP_INSIDE_GROUP = 6,
    GAP_BETWEEN_GROUPS = 6,
    FRAME_X = 640,
    FRAME_Y= -70,
    LOCK_FRAME = true,
    BLOOD_RUNE_COLOR = {1, 0, 0},
    UNHOLY_RUNE_COLOR = {103 / 255, 249 / 255, 112 / 255},
    FROST_RUNE_COLOR = {81 / 255, 153 / 255, 1},
    DEATH_RUNE_COLOR = {190/255, 57/255, 1},
    OUT_OF_COMBAT_ALPHA = 0.4,
    IN_COMBAT_ALPHA = 1,
}

core.barIndices = {
    1, -- Blood Rune
    2, -- Blood Rune
    5, -- Frost Rune
    6, -- Frost Rune
    3, -- Unholy Rune
    4, -- Unholy Rune
}

local function GetRuneGroup(rune_index)
    if not rune_index then return end
    local rune_group = 2

    if rune_index <= 2 then
        rune_group = 0
    elseif rune_index <= 4 then
        rune_group = 1
    elseif rune_index <= 6 then
        rune_group = 2
    end

    return rune_group
end

local function split_string(input, delimiter)
    local result = {}
    for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

local function GetBarIndex(rune_index)
    return core.barIndices[rune_index]
end

local CreateBar = function(rune_index)
    local bar = CreateFrame("StatusBar", "Rune_" .. rune_index, core.frame)
    bar.rune_index = rune_index
    bar.bar_index = GetBarIndex(rune_index)
    bar.rune_group = GetRuneGroup(rune_index)

    bar:SetSize(core.config.BAR_WIDTH, core.config.BAR_HEIGHT)
    bar:SetStatusBarTexture("Interface/Addons/DeathKnightRunes/media/statusbar/bar_background.tga")
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:GetStatusBarTexture():SetVertTile(false)
    bar:SetMinMaxValues(0, 8.33)  -- Rune regen will be around 8.33 seconds at most
    bar:SetValue(8.33) -- Set the initial bar to be full

     -- Set the position of the bar
    local group = math.floor((rune_index - 1) / 2)
    local rang = (rune_index - 1) % 2
    local x_offset = (rune_index - 1) * core.config.BAR_WIDTH + group * core.config.GAP_BETWEEN_GROUPS + (rang + group) * core.config.GAP_INSIDE_GROUP
    bar:SetPoint("LEFT", UIParent, "LEFT", core.config.FRAME_X + x_offset, core.config.FRAME_Y)

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

        local color = core.config.BLOOD_RUNE_COLOR
        if rune_type == 2 then
            color = core.config.UNHOLY_RUNE_COLOR
        elseif rune_type == 3 then
            color = core.config.FROST_RUNE_COLOR
        elseif rune_type == 4 then
            color = core.config.DEATH_RUNE_COLOR  -- Death Runes: Purple
        end
        bar:SetStatusBarColor(unpack(color))  -- Unholy Runes: Green
    end

    bar.UpdateProgress = function(self, start, rune_cd, rune_ready)

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
    end)

    return bar
end


local CreateRunesFrame = function()

    core.frame = CreateFrame("Frame", "DeathStrikeRunesFrame", UIParent)
    local frame = core.frame

    -- Set the position of the frame
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetAlpha(core.config.OUT_OF_COMBAT_ALPHA)

    frame.bars = {}
    for rune_index = 1, 6 do
        frame.bars[rune_index] = CreateBar(rune_index)
    end

    frame.UpdateRune = function(self, rune_index)
        local start, rune_cd, rune_ready = GetRuneCooldown(rune_index)
        local bar = frame.bars[GetBarIndex(rune_index)]
        bar:UpdateProgress(start, rune_cd, rune_ready)
    end

    -- Updates the type and CD of all runes
    frame.UpdateAllRunes = function(self)
        for rune_index = 1, 6 do
            frame:UpdateRune(rune_index)
        end
    end

    -- Event handler for tracking runes
    frame:SetScript("OnEvent", function(self, event, rune_index, ...)

        local bar_index = GetBarIndex(rune_index)

        if event == "RUNE_POWER_UPDATE" then
            if rune_index then
                frame:UpdateRune(rune_index)
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
            frame:UpdateAllRunes()
        end

        return true
    end)

    -- Update each rune with the current values
    frame:SetScript("OnShow", function()
        frame:UpdateAllRunes()
    end)


    -- Drag functionality
    frame:SetScript("OnDragStart", function(self)

        if core.config.LOCK_FRAME then
            return
        end

        frame:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)

        if core.config.LOCK_FRAME then
            return
        end

        frame:StopMovingOrSizing()

        -- Save the new position for future use
        local point, parent, relativePoint, xOffset, yOffset = self:GetPoint()
        frame.config.FRAME_X = xOffset
        frame.config.FRAME_Y = yOffset

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
