local ADDON_NAME, core = ...;

local function CreateOrderedTable()
    local ordered = {
        _keys = {},
    }

    return setmetatable(ordered, {
        __newindex = function(t, key, value)
            if rawget(t, key) == nil then
                table.insert(t._keys, key)
            end
            rawset(t, key, value)
        end,
        __index = function(t, key)
            return rawget(t, key)
        end,
    })
end

core.defaultConfig = CreateOrderedTable()

-- Global Settings
core.defaultConfig.LOCK_FRAME = {
    type = "checkbox",
    label = "Lock all frames",
    default = true,
}
core.defaultConfig.IN_COMBAT_ALPHA = {
    type = "float",
    label = "Frame Alpha (In Combat)",
    default = 1,
}
core.defaultConfig.OUT_OF_COMBAT_ALPHA = {
    type = "float",
    label = "Frame Alpha (Out of Combat)",
    default = 0.4,
}

-- Rune Frame Settings
core.defaultConfig.RUNE_HEADER = {
    type = "header",
    label = "Rune Settings",
}
core.defaultConfig.FRAME_X = {
    type = "float",
    label = "Frame Position X (from center)",
    default = 0,
}
core.defaultConfig.FRAME_Y = {
    type = "float",
    label = "Frame Position Y (from center)",
    default = -70,
}
core.defaultConfig.BAR_WIDTH = {
    type = "float",
    label = "Rune Bar Width",
    default = 35,
}
core.defaultConfig.BAR_HEIGHT = {
    type = "float",
    label = "Rune Bar Height",
    default = 20,
}
core.defaultConfig.BORDER_THICKNESS = {
    type = "float",
    label = "Rune Bar Border Thickness",
    default = 0,
}
core.defaultConfig.GAP_INSIDE_GROUP = {
    type = "float",
    label = "Gap Inside Rune Group",
    default = 6,
}
core.defaultConfig.GAP_BETWEEN_GROUPS = {
    type = "float",
    label = "Gap Between Rune Groups",
    default = 6,
}
core.defaultConfig.TEXT_CD_SIZE = {
    type = "float",
    label = "Rune Cooldown Font Size",
    default = 12,
}
core.defaultConfig.BACKGROUND_ALPHA = {
    type = "float",
    label = "Bar Background Alpha",
    default = 0.6,
}
core.defaultConfig.BLOOD_RUNE_COLOR = {
    type = "color",
    label = "Blood Rune Color",
    default = {1, 0, 0},
}
core.defaultConfig.UNHOLY_RUNE_COLOR = {
    type = "color",
    label = "Unholy Rune Color",
    default = {103 / 255, 249 / 255, 112 / 255},
}
core.defaultConfig.FROST_RUNE_COLOR = {
    type = "color",
    label = "Frost Rune Color",
    default = {81 / 255, 153 / 255, 1},
}
core.defaultConfig.DEATH_RUNE_COLOR = {
    type = "color",
    label = "Death Rune Color",
    default = {190 / 255, 57 / 255, 1},
}

-- Runic Power Frame Settings
core.defaultConfig.RUNIC_POWER_HEADER = {
    type = "header",
    label = "Runic Power Settings",
}
core.defaultConfig.RP_BAR_WIDTH = {
    type = "float",
    label = "Runic Power Bar Width",
    default = 220,
}
core.defaultConfig.RP_BAR_HEIGHT = {
    type = "float",
    label = "Runic Power Bar Height",
    default = 20,
}
core.defaultConfig.RP_BORDER_THICKNESS = {
    type = "float",
    label = "Runic Power Border Thickness",
    default = 0,
}
core.defaultConfig.RP_FRAME_X = {
    type = "float",
    label = "Runic Power Frame Position X",
    default = 10,
}
core.defaultConfig.RP_FRAME_Y = {
    type = "float",
    label = "Runic Power Frame Position Y",
    default = -30,
}
core.defaultConfig.RP_TEXT_SIZE = {
    type = "float",
    label = "Runic Power Font Size",
    default = 12,
}
core.defaultConfig.RP_BAR_COLOR = {
    type = "color",
    label = "Runic Power Bar Color",
    default = {165 / 255, 152 / 255, 249 / 255},
}


-- If DeathStrikeHealingMeterDB doesn't exist, initialize it with default values
if not RunesDB then
    RunesDB = {}
end

-- Function to save the one config value into the SavedVariables table
core.SetConfigValue = function(key, value)
    if value ~= nil then
        RunesDB[key] = value
        core.config = core.GetConfig()
    elseif core.defaultConfig[key] and core.defaultConfig[key].default then
        RunesDB[key] = core.defaultConfig[key].default
        core.config = core.GetConfig()
    end
end

core.GetConfigValue = function(key)
    if RunesDB and RunesDB[key] ~= nil then
        return RunesDB[key]
    elseif core.defaultConfig and core.defaultConfig[key] and core.defaultConfig[key].default ~= nil then
        return core.defaultConfig[key].default
    else
        return nil  -- unknown config key
    end
end

-- Function to load the current config as a read-only table
core.GetConfig = function()
    local config = {}
    for key, option in pairs(core.defaultConfig) do
        config[key] = RunesDB[key] or option.default
    end

    config.TOTAL_WIDTH = (6 * config.BAR_WIDTH)
                        + (2 * config.GAP_BETWEEN_GROUPS)
                        + (3 * config.GAP_INSIDE_GROUP) -- 3 spaces between 4 pairs
    config.TOTAL_HEIGHT = config.BAR_HEIGHT + max(abs(config.RP_FRAME_Y), abs(config.FRAME_Y)) + config.RP_BAR_HEIGHT
    return config
end


core.Round = function(n, decimals)
    if n == nil then
        return
    end

    local mult = 10 ^ (decimals or 0)
    return math.floor(n * mult + 0.5) / mult
end
