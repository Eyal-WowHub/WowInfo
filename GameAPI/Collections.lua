local _, addon = ...
local Collections = addon:NewObject("Collections")

local CACHE = {
    numCollectedMounts = 0
}

local function CacheNumMounts()
    local numMounts = C_MountJournal.GetNumMounts()
    if numMounts >= 1 then
        local numCollectedMounts = 0
        local hideOnChar, isCollected
        local mountIDs = C_MountJournal.GetMountIDs()
        for _, mountID in ipairs(mountIDs) do
            hideOnChar, isCollected = select(10, C_MountJournal.GetMountInfoByID(mountID))
            if isCollected and hideOnChar ~= true then
                numCollectedMounts = numCollectedMounts + 1
            end
        end
        CACHE.numCollectedMounts = numCollectedMounts
    else
        CACHE.numCollectedMounts = 0
    end
end

Collections:RegisterEvents(
    "PLAYER_LOGIN",
    "COMPANION_LEARNED",
    "COMPANION_UNLEARNED", function(_, eventName)
        CacheNumMounts()
    end)

function Collections:GetTotalMounts()
    if CACHE.numCollectedMounts > 0 then
        return CACHE.numCollectedMounts
    end
    return nil
end

function Collections:GetTotalPets()
    local _, numOwnedPets = C_PetJournal.GetNumPets()
    if numOwnedPets > 0 then
        return numOwnedPets
    end
    return nil
end

function Collections:GetTotalToys()
    local numToys, learnedToys = C_ToyBox.GetNumTotalDisplayedToys(), C_ToyBox.GetNumLearnedDisplayedToys()
    if learnedToys > 0 then
        return learnedToys, numToys
    end
    return nil
end