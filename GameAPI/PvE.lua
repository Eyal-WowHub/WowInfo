local _, addon = ...
local PvE = addon:NewObject("PvE")

local INFO = {
    Instance = {},
    WorldBoss = {}
}

PvE:RegisterEvent("PLAYER_LOGIN", function()
    RequestRaidInfo()
end)

function PvE:IterableInstanceInfo()
    local i = 0
    local n = GetNumSavedInstances()
    return function()
        i = i + 1
        while i <= n do
            local instanceName, _, reset, instanceDifficulty, locked, extended, _, _, _, _, maxBosses, defeatedBosses = GetSavedInstanceInfo(i)
            local difficultyName = GetDifficultyInfo(instanceDifficulty)
            
            if locked or extended then
                INFO.Instance.name = instanceName
                INFO.Instance.reset = reset
                INFO.Instance.difficulty = difficultyName
                INFO.Instance.isCleared = defeatedBosses >= maxBosses
                INFO.Instance.defeatedBosses = defeatedBosses
                INFO.Instance.maxBosses = maxBosses
                return INFO.Instance
            end

            i = i + 1
        end
    end
end

function PvE:IterableSavedWorldBossInfo()
    local i = 0
    local n = GetNumSavedWorldBosses()
    return function()
        i = i + 1
        if i <= n then
            local name, _, reset = GetSavedWorldBossInfo(i)
            INFO.WorldBoss.name = name
            INFO.WorldBoss.reset = reset
            return INFO.WorldBoss
        end
    end
end