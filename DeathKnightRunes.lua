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

core.runeIndices = {
    1, -- Blood Rune
    2, -- Blood Rune
    5, -- Frost Rune
    6, -- Frost Rune
    3, -- Unholy Rune
    4, -- Unholy Rune
}

local function GetRuneIndex(index)
    return core.runeIndices[index]
end

local function GetRuneGroup(index)
    if not index then return end
    local rune_group = 2

    if index <= 2 then
        rune_group = 0
    elseif index <= 4 then
        rune_group = 1
    elseif index <= 6 then
        rune_group = 2
    end

    return rune_group
end

local CreateBar = function(index)
    local bar = CreateFrame("StatusBar", "Rune_" .. index, core.frame)
    bar.index = index
    bar.rune_index = GetRuneIndex(index)
    bar.rune_group = GetRuneGroup(index)
    bar.extra_cd = 0
    bar.frozen = false

    bar:SetSize(core.config.BAR_WIDTH, core.config.BAR_HEIGHT)
    bar:SetStatusBarTexture("Interface/Addons/DeathKnightRunes/media/statusbar/bar_background.tga")
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:GetStatusBarTexture():SetVertTile(false)
    bar:SetMinMaxValues(0, 8.33)  -- Rune regen will be around 8.33 seconds at most
    bar:SetValue(8.33) -- Set the initial bar to be full

     -- Set the position of the bar
    local group = math.floor((index - 1) / 2)
    local rang = (index - 1) % 2
    local x_offset = (index - 1) * core.config.BAR_WIDTH + group * core.config.GAP_BETWEEN_GROUPS + (rang + group) * core.config.GAP_INSIDE_GROUP
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
            color = core.config.FROST_RUNE_COLOR
        elseif rune_type == 3 then
            color = core.config.UNHOLY_RUNE_COLOR
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
    for index = 1,6 do
        frame.bars[index] = CreateBar(index)
    end

    -- Updates the type and CD of a rune
    frame.UpdateRunes = function(self, index)  -- # 5: frost => 3 frost

        local rune_1 = GetRuneIndex(self.rune_group * 2 + 1)
        local rune_2 = GetRuneIndex(rune_1 + 1)

        local bar_1 = frame.bars[rune_1]
        local bar_2 = frame.bars[rune_2]

        local now = GetTime()
        local start_1, rune_cd_1, rune_ready_1 = GetRuneCooldown(rune_1)
        local start_2, rune_cd_2, rune_ready_2 = GetRuneCooldown(rune_2)

        if not rune_ready_2 then
            if not rune_ready_1 then
                if start_2 > start_1 then
                    bar_2.extra_cd = start_1 + rune_cd_1 - now
                    bar_1.extra_cd = 0
                    bar_2.frozen = true
                    bar_1.frozen = false
                else
                    bar_1.extra_cd = start_2 + rune_cd_2 - now
                    bar_2.extra_cd = 0
                    bar_1.frozen = true
                    bar_2.frozen = false
                end

            end
        end

        if index == rune_1 then
            if start_1 + rune_cd_1 + bar_1.extra_cd <= now + 0.01 then
                bar_1.frozen = false
                bar_1.extra_cd = 0
             end
        end

        if index == rune_2 then
            if start_2 + rune_cd_2 + bar_2.extra_cd <= now + 0.01 then
                bar_2.frozen = false
                bar_2.extra_cd = 0
            end
        end

        if bar_2.frozen then
            rune_cd_2 = rune_cd_2 + bar_2.extra_cd
        end
        if bar_1.frozen then
            rune_cd_1 = rune_cd_1 + bar_1.extra_cd
        end

        bar_1:UpdateProgress(start_1, rune_cd_1, rune_ready_1)
        bar_2:UpdateProgress(start_2, rune_cd_2, rune_ready_2)
    end

    -- Updates the type and CD of all runes
    frame.UpdateAllRunes = function()
        for rune_index = 1, 5, 2 do
            frame:UpdateRunes(rune_index)
        end
    end

    -- Event handler for tracking runes
    frame:SetScript("OnEvent", function(self, event, rune_index, ...)

        local _, class_id = UnitClassBase("player");
        if class_id ~= 6 then
            return
        end

        if event == "RUNE_POWER_UPDATE" then
            if rune_index then
                frame:UpdateRunes(rune_index)
            end

        elseif event == "RUNE_TYPE_UPDATE" then
            if rune_index then
                frame.bars[rune_index]:SetRuneColor()
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

    frame:SetScript("OnShow", function()
        -- Update each rune with the current values
        for rune_index = 1, 6 do
            frame:UpdateRunes(rune_index)
        end
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
