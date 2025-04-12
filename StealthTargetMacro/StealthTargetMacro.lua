-- This AddOn creates and updates a macro for targeting the highest level rogue or druid you kill during a fight.
-- The macro is updated automatically after every fight as soon as you leave combat.
-- The macro targets the player, casts Hunter's Mark and sends your pet to attack.
-- You can bind this macro to your action bar and use it to easily corpse camp rogues and druids:
-- Just spam this macro while you wait for them to resurrect.
-- However, I do not endorse this behavior in any way!
local rogueNameToUpdate = nil
local highestRogueLevel = 0
local knownPlayerLevels = {}


local function UpdateMacro(playerName)
    local macroText = string.format("#showtooltip\n/targetexact %s\n/cast Hunter's Mark\n/petattack", playerName)
    local macroIndex = GetMacroIndexByName("StealthTarget")
    if macroIndex > 0 then
        EditMacro(macroIndex, nil, nil, macroText)
        print("[StealthTargetMacro]: Macro updated with name " .. playerName)
    else
        print("[StealthTargetMacro]: Error: Macro 'StealthTarget' not found.")
    end
end

local function CreateMacroIfNotExists()
    local macroIndex = GetMacroIndexByName("StealthTarget")
    if macroIndex == 0 then
        local macroId = CreateMacro("StealthTarget", "INV_MISC_QUESTIONMARK",
            "#showtooltip\n/targetexact\n/cast Hunter's Mark\n/petattack", nil) -- nil for character-specific macros
        if macroId then
            print("[Stealth Target Macro]: Macro 'StealthTarget' created (in General Macros). You need to bind it to your action bar.")
        else
            print("[Stealth Target Macro]: Error: Failed to create macro 'StealthTarget'.")
        end
    else
        -- print("Macro 'StealthTarget' already exists with index: " .. macroIndex)
    end
end

local function IsRogueOrDruid(class)
    return class and (class:upper() == "ROGUE" or class:upper() == "DRUID")
end

local function StorePlayerInfo(unit)
    if UnitIsPlayer(unit) then
        local name = UnitName(unit)
        local _, class = UnitClass(unit)
        if not IsRogueOrDruid(class) then return end

        local level = UnitLevel(unit)
        knownPlayerLevels[name] = (level == -1) and 200 or level -- Treat "??" as very high level
        -- DEFAULT_CHAT_FRAME:AddMessage("Stored player info: " .. name .. ", level: " .. knownPlayerLevels[name] .. ", class: " .. class)
    end
end


local function HandleCombatLogEvent(destName)
    if not knownPlayerLevels[destName] then
        return
    end

    rogueNameToUpdate = destName
    if knownPlayerLevels[destName] and knownPlayerLevels[destName] > highestRogueLevel then
        highestRogueLevel = knownPlayerLevels[destName]
        rogueNameToUpdate = destName
    end
end


local function OnEvent(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, _, _, _, destName, unitName = CombatLogGetCurrentEventInfo()

        if subEvent == "UNIT_DIED" and bit.band(unitName, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 then
            if bit.band(unitName, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 then
                HandleCombatLogEvent(destName)
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if rogueNameToUpdate then
            UpdateMacro(rogueNameToUpdate)
            rogueNameToUpdate = nil
            highestRogueLevel = 0
        end
    elseif event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "StealthTargetMacro" then
            C_Timer.After(1, CreateMacroIfNotExists)
        end
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        StorePlayerInfo("mouseover")
    elseif event == "PLAYER_TARGET_CHANGED" then
        StorePlayerInfo("target")
    end
end


local addonFrame = CreateFrame("Frame")
addonFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
addonFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
addonFrame:RegisterEvent("ADDON_LOADED")
addonFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
addonFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
addonFrame:SetScript("OnEvent", OnEvent)
