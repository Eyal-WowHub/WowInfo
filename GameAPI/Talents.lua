local _, addon = ...
local Talents = addon:NewObject("Talents")

local INFO = {
    Trait = {}
}

local CACHE = {
    Traits = {}
}

local function CacheLoadoutsInfo()
    local specID = specID or PlayerUtil.GetCurrentSpecID()
    local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)
    local size = math.max(#configIDs, #CACHE.Traits)
    for i = 1, size do
        local configID = configIDs[i]
        local data = CACHE.Traits[i]
        if configID then
            local isActive = false
            local configInfo = C_Traits.GetConfigInfo(configID)
            
            if not data then
                CACHE.Traits[i] = {}
                data = CACHE.Traits[i]
            end

            data.name = configInfo.name
            data.usesSharedActionBars = configInfo.usesSharedActionBars
            data.configID = configID
            data.specID = specID
        else
            CACHE.Traits[i] = nil
        end
    end
end

Talents:RegisterEvents(
    "PLAYER_LOGIN",
    "ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
    "SELECTED_LOADOUT_CHANGED", 
    "TRAIT_CONFIG_CREATED",
    "TRAIT_CONFIG_DELETED",
    "TRAIT_CONFIG_UPDATED",
    "TRAIT_CONFIG_LIST_UPDATED",
    function(_, eventName)
        CacheLoadoutsInfo()
    end)

function Talents:GetCurrentSpec()
    local _, classFilename = UnitClass("player")
    local specName
    local currentSpecID = PlayerUtil.GetCurrentSpecID()

    for i = 1, GetNumSpecializations() do
        local id, name = GetSpecializationInfo(i)
        if id == currentSpecID then
            specName = name
            break
        end
    end

    return specName
end

function Talents:HasLoadouts()
    return #CACHE.Traits > 0 and true or false
end

function Talents:IterableLoadoutsInfo()
    INFO.Trait.name = nil
    INFO.Trait.usesSharedActionBars = nil
    INFO.Trait.isActive = nil

    local isStarterBuildActive = self:IsStarterBuildActive()
    local i = 0
    local n = #CACHE.Traits

    return function()
        i = i + 1
        if i <= n then
            local data = CACHE.Traits[i]

            INFO.Trait.name = data.name
            INFO.Trait.usesSharedActionBars = data.usesSharedActionBars
            INFO.Trait.isActive = false

            local lastSelectedSavedConfigID = C_ClassTalents.GetLastSelectedSavedConfigID(data.specID)

            if not isStarterBuildActive and data.configID == lastSelectedSavedConfigID then
                INFO.Trait.isActive = true
            end
            
            return INFO.Trait
        end
    end
end

function Talents:IsStarterBuildActive()
    local hasStarterBuild = C_ClassTalents.GetHasStarterBuild()
    if hasStarterBuild then
        return C_ClassTalents.GetStarterBuildActive()
    end
end

function Talents:HasPvpTalents()
    for name in self:IteratablePvpTalents() do
        if name then
            return true
        end
    end
    return false
end

function Talents:IteratablePvpTalents()
    local i = 0
    local t = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
    local n = #t
    return function()
        i = i + 1
        while i <= n do
            local talentID = t[i]
            if talentID then
                local _, name, icon, _, _, _, unlocked = GetPvpTalentInfoByID(talentID)
                if name then
                    return name, icon, unlocked
                end
            end
            i = i + 1
        end
    end
end