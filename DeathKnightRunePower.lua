local ADDON_NAME, core = ...;

local config = {
    BACKGROUND_ALPHA = 0.6,
    TEXT_CD_SIZE = 12,
    BAR_WIDTH = 220,
    BAR_HEIGHT = 20,
    BORDER_THICKNESS = 0,
    FRAME_X = 650,
    FRAME_Y= -100,
    LOCK_FRAME = true,
    OUT_OF_COMBAT_ALPHA = 0.4,
    BAR_COLOR = {165/255, 152/255, 249/255},
    IN_COMBAT_ALPHA = 1,
}

local CreateBar = function(index)
    local bar = CreateFrame("StatusBar", "RunePower", core.frame)

    bar:SetSize(config.BAR_WIDTH, config.BAR_HEIGHT)
    bar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill")
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:GetStatusBarTexture():SetVertTile(false)
    bar:GetStatusBarTexture():SetDrawLayer("ARTWORK")  -- Set the bar texture layer to "ARTWORK"
    bar:SetMinMaxValues(0, UnitPowerMax("player", Enum.PowerType.RunicPower))
    bar:SetValue(UnitPower("player", Enum.PowerType.RunicPower))
    bar:SetStatusBarColor(unpack(config.BAR_COLOR))

     -- Set the position of the bar
    bar:SetPoint("LEFT", UIParent, "LEFT", config.FRAME_X, config.FRAME_Y)

    -- Create a Background for the bar
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints(true)
    bar.bg:SetColorTexture(0, 0, 0, config.BACKGROUND_ALPHA)

    -- Create a border around the bar
    if config.BORDER_THICKNESS > 0 then
        bar.border = CreateFrame("Frame", nil, bar, BackdropTemplateMixin and "BackdropTemplate")
        bar.border:SetPoint("TOPLEFT", -config.BORDER_THICKNESS, config.BORDER_THICKNESS)
        bar.border:SetPoint("BOTTOMRIGHT", config.BORDER_THICKNESS, -config.BORDER_THICKNESS)
        bar.border:SetBackdrop({
            edgeFile = "Interface/CharacterFrame/UI-Party-Border",  -- A standard thin border texture
            edgeSize = config.BORDER_THICKNESS,
        })
        bar.border:SetBackdropBorderColor(1, 1, 1)  -- White border color; adjust as needed
    end

    -- Text for the bar
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.text:SetFont("Fonts/FRIZQT__.TTF", config.TEXT_CD_SIZE, "OUTLINE")
    bar.text:SetTextColor(1, 1, 1)
    bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar.text:SetJustifyH("CENTER")

    bar.SetRunePowerGlow = function(self)
        if self:GetValue() > 100 then
        end
    end

    -- Event handler for tracking rune power
    bar:SetScript("OnUpdate", function(self, elapsed, ...)
        self.lastUpdate = self.lastUpdate or GetTime()

        if GetTime() > self.lastUpdate + 0.1 then
            self:SetMinMaxValues(0, UnitPowerMax("player", Enum.PowerType.RunicPower))
            self:SetValue(UnitPower("player", Enum.PowerType.RunicPower))
            self.text:SetText(UnitPower("player", Enum.PowerType.RunicPower))
            self:SetRunePowerGlow()
            self.lastUpdate = GetTime()
        end
    end)

    bar:SetRunePowerGlow()

    return bar
end

local CreateRunePowerFrame = function()

    core.frame = CreateFrame("Frame", "DeathStrikeRunesFrame", UIParent)
    local frame = core.frame

    -- Set the position of the frame
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetAlpha(config.OUT_OF_COMBAT_ALPHA)

    frame.bar = CreateBar()

    -- Event handler for tracking runes
    frame:SetScript("OnEvent", function(self, event, ...)

        if event == "PLAYER_REGEN_ENABLED" then
            frame:SetAlpha(config.OUT_OF_COMBAT_ALPHA)

        elseif event == "PLAYER_REGEN_DISABLED" then
            frame:SetAlpha(config.IN_COMBAT_ALPHA)

        end
        return true
    end)

    -- Drag functionality
    frame:SetScript("OnDragStart", function(self)

        if config.LOCK_FRAME then
            return
        end

        frame:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)

        if config.LOCK_FRAME then
            return
        end

        frame:StopMovingOrSizing()
        -- Optionally save the new position for future use
        local point, parent, relativePoint, xOffset, yOffset = self:GetPoint()
        frame.config.FRAME_X = xOffset
        frame.config.FRAME_Y = yOffset
    end)
    --PLAYER_ENTERING_WORLD RUNE_TYPE_UPDATE RUNE_POWER_UPDATE PLAYER_REGEN_DISABLED PLAYER_REGEN_ENABLED
    
    -- Register events to track runes
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
end


local _, class_id = UnitClassBase("player");
if class_id == 6 then
    CreateRunePowerFrame()
end
