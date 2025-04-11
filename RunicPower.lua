local ADDON_NAME, core = ...;

local CreateRunePowerBar = function(index)
    local config = core.GetConfig()

    local bar = CreateFrame("StatusBar", "RunePower", core.frame)

    bar:SetSize(config.RP_BAR_WIDTH, config.RP_BAR_HEIGHT)
    bar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill")
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:GetStatusBarTexture():SetVertTile(false)
    bar:GetStatusBarTexture():SetDrawLayer("ARTWORK")  -- Set the bar texture layer to "ARTWORK"
    bar:SetMinMaxValues(0, UnitPowerMax("player", Enum.PowerType.RunicPower))
    bar:SetValue(UnitPower("player", Enum.PowerType.RunicPower))
    bar:SetStatusBarColor(unpack(config.RP_BAR_COLOR))

     -- Set the position of the bar
    bar:SetPoint("LEFT", core.frame, "LEFT", config.RP_FRAME_X, config.RP_FRAME_Y)

    -- Create a Background for the bar
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints(true)
    bar.bg:SetColorTexture(0, 0, 0, config.BACKGROUND_ALPHA)

    -- Create a border around the bar
    if config.BORDER_THICKNESS > 0 then
        bar.border = CreateFrame("Frame", nil, bar, BackdropTemplateMixin and "BackdropTemplate")
        bar.border:SetPoint("TOPLEFT", -config.RP_BORDER_THICKNESS, config.RP_BORDER_THICKNESS)
        bar.border:SetPoint("BOTTOMRIGHT", config.RP_BORDER_THICKNESS, -config.RP_BORDER_THICKNESS)
        bar.border:SetBackdrop({
            edgeFile = "Interface/CharacterFrame/UI-Party-Border",  -- A standard thin border texture
            edgeSize = config.RP_BORDER_THICKNESS,
        })
        bar.border:SetBackdropBorderColor(1, 1, 1)  -- White border color; adjust as needed
    end

    -- Text for the bar
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.text:SetFont("Fonts/FRIZQT__.TTF", config.RP_TEXT_SIZE, "OUTLINE")
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

local _, class_id = UnitClassBase("player");
if class_id == 6 then
    core.frame.power = CreateRunePowerBar()
end
