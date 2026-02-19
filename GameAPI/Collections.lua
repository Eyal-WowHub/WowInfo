local _, addon = ...
local Collections = addon:NewObject("Collections")

local CACHE = {
    numCollectedMounts = 0
}

local NUM_BATTLE_PETS_IN_BATTLE = 3

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

function Collections:GetLoadedPetsInfo()
    local pets
    for slot = 1, NUM_BATTLE_PETS_IN_BATTLE do
        local petID = C_PetJournal.GetPetLoadOutInfo(slot)
        if petID then
            local _, customName, _, _, _, _, _, name, icon = C_PetJournal.GetPetInfoByPetID(petID)
            local health, maxHealth = C_PetJournal.GetPetStats(petID)
            if health and maxHealth then
                pets = pets or {}
                pets[#pets + 1] = {
                    name = (customName and customName ~= "") and customName or name,
                    healthPct = (maxHealth > 0) and (health / maxHealth) or 0,
                    icon = icon
                }
            end
        end
    end
    return pets
end

function Collections:HasDeadPets()
    local pets = self:GetLoadedPetsInfo()
    if not pets then
        return false, 0
    end
    local deadCount = 0
    for _, pet in ipairs(pets) do
        if pet.healthPct == 0 then
            deadCount = deadCount + 1
        end
    end
    return deadCount > 0, deadCount
end