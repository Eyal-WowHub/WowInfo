local _, addon = ...
local Delves = addon:NewObject("Delves")

local INFO = {
    seasonNumber = 0
}

local CACHE = {
    Renown = {
        currentValue = -1
    },
    Companion = {}
}

local MIN_REP_RANK_FOR_REWARDS = 1
local MIN_REP_THRESHOLD_BAR_VALUE = MIN_REP_RANK_FOR_REWARDS - 1
local MAX_REP_RANK_FOR_REWARDS = 10

local function CacheFactionData()
    local companionFactionID = C_DelvesUI.GetFactionForCompanion()
    if companionFactionID == 0 then return end
    
    local friendshipData = C_GossipInfo.GetFriendshipReputation(companionFactionID)
   
    if friendshipData and friendshipData.friendshipFactionID > 0 then
        local companionFactionInfo = C_Reputation.GetFactionDataByID(companionFactionID)
        
        CACHE.Companion.name = companionFactionInfo.name

        local rankInfo = C_GossipInfo.GetFriendshipReputationRanks(friendshipData.friendshipFactionID)

        if rankInfo.maxLevel > 0 then
            CACHE.Companion.currentLevel = rankInfo.currentLevel
            CACHE.Companion.maxLevel = rankInfo.maxLevel
        end

        local renownInfo = C_MajorFactions.GetMajorFactionRenownInfo(C_DelvesUI.GetDelvesFactionForSeason())
        local renownLevel = renownInfo.renownLevel
        local value = renownInfo.renownReputationEarned / renownInfo.renownLevelThreshold
    
        CACHE.Renown.currentValue = renownInfo and (RoundToSignificantDigits(renownInfo.renownLevel + value, 1)) or 0
    else
        CACHE.Companion.currentLevel = 0
        CACHE.Companion.maxLevel = 0
        CACHE.Renown.currentValue = -1
	end
end

Delves:RegisterEvents(
    "MAJOR_FACTION_RENOWN_LEVEL_CHANGED", 
    "MAJOR_FACTION_UNLOCKED",
    "UPDATE_FACTION", CacheFactionData)

function Delves:GetProgressInfo()
    local seasonNumber = C_DelvesUI.GetCurrentDelvesSeasonNumber()
    local isActiveSeason = seasonNumber and seasonNumber > 0

    if isActiveSeason and CACHE.Renown.currentValue > -1 then
        local currExpID = GetExpansionLevel()
        local expName = _G["EXPANSION_NAME" .. currExpID]

        INFO.seasonNumber = seasonNumber
        INFO.expansion = expName
        INFO.companionName = CACHE.Companion.name
        INFO.companionLevel = CACHE.Companion.currentLevel
        INFO.companionMaxLevel = CACHE.Companion.maxLevel
        INFO.currentValue = CACHE.Renown.currentValue
        INFO.maxValue = MAX_REP_RANK_FOR_REWARDS

        return INFO
    end

    return nil
end