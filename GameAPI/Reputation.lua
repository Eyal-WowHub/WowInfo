local _, addon = ...
local Reputation = addon:NewObject("Reputation")

local INFO = {
    ProgressInfo = {}
}

local DATA = {
    ProgressInfo = {},
    CollapsedIndexes = {}
}

local CACHE = {
    numFactions = 0
}

local MAJOR_FACTION_MAX_RENOWN_REACHED = MAJOR_FACTION_MAX_RENOWN_REACHED
local MAJOR_FACTION_RENOWN_LEVEL_TOAST = MAJOR_FACTION_RENOWN_LEVEL_TOAST
local MAX_REPUTATION_REACTION = MAX_REPUTATION_REACTION

local function FillFactionProgressInfo(faction)
    local factionID = faction.factionID
    local standingID = faction.reaction
    local repMin, repMax, repValue = faction.currentReactionThreshold, faction.nextReactionThreshold, faction.currentStanding

    local gender = UnitSex("player")
    local standing = GetText("FACTION_STANDING_LABEL" .. standingID, gender)

    local progressType = 0
    local renownLevel = 0
    local isCapped, hasReward = false, false

    if C_Reputation.IsMajorFaction(factionID) then
        local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID)
        repMin, repMax = 0, majorFactionData.renownLevelThreshold
        isCapped = C_MajorFactions.HasMaximumRenown(factionID)
        repValue = isCapped and majorFactionData.renownLevelThreshold or majorFactionData.renownReputationEarned or 0
        renownLevel = majorFactionData.renownLevel
        if isCapped then
            standing = MAJOR_FACTION_MAX_RENOWN_REACHED
        else
            standing = MAJOR_FACTION_RENOWN_LEVEL_TOAST:format(renownLevel)
        end
        local _, _, rewardQuestID, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionID)
        if not tooLowLevelForParagon and (rewardQuestID or hasRewardPending) then
			hasReward = true
		end
        progressType = 3
    elseif C_Reputation.IsFactionParagon(factionID) then
        local currentValue, threshold, _, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionID)
        repMin, repMax, repValue = 0, threshold, currentValue % threshold
        if not tooLowLevelForParagon and hasRewardPending then
            hasReward = true
        end
        progressType = 2
    else
        local repInfo = C_GossipInfo.GetFriendshipReputation(factionID)
        if repInfo and repInfo.friendshipFactionID and repInfo.friendshipFactionID > 0 then
            if repInfo.nextThreshold then
                repMin, repMax, repValue = repInfo.reactionThreshold, repInfo.nextThreshold, repInfo.standing
            else
                repMin, repMax, repValue = 0, 1, 1
                isCapped = true
            end
            standingID = 5 -- Always color friendship factions with green
            standing = repInfo.reaction
            progressType = 1
        elseif standingID == MAX_REPUTATION_REACTION then
            isCapped = true
            repMin, repMax, repValue = 0, 1, 1
        end
    end

    repMax = repMax - repMin
    repValue = repValue - repMin

    DATA.ProgressInfo.type = progressType
    DATA.ProgressInfo.standing = standing
    DATA.ProgressInfo.renownLevel = renownLevel
    DATA.ProgressInfo.standingID = standingID
    DATA.ProgressInfo.isCapped = isCapped
    DATA.ProgressInfo.currentValue = repValue
    DATA.ProgressInfo.maxValue = repMax
    DATA.ProgressInfo.hasReward = hasReward
end

local function HasParagonRewardPending(factionID)
    local hasParagonRewardPending = false
    if factionID then
        if C_Reputation.IsFactionParagon(factionID) then
            local _, _, _, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionID)
            if not tooLowLevelForParagon and hasRewardPending then
                hasParagonRewardPending = true
            end
        end
    end
    return hasParagonRewardPending
end

local function IsTrackedFaction(factionID)
    local shouldAlwaysShowParagon = Reputation.storage:GetAlwaysShowParagon() and HasParagonRewardPending(factionID)
    if factionID and Reputation.storage:IsSelectedFaction(factionID) or shouldAlwaysShowParagon then
        return true
    end
    return false
end

local function CacheFactionData()
    if Reputation.__cachedNumFactions ~= CACHE.numFactions then
        -- NOTE: 'ExpandFactionHeader' and 'CollapseFactionHeader' trigger UPDATE_FACTION and may cause infinite recursion,
        -- so we are unregistering the event before these functions are called and registering it again after they are called.
        Reputation:UnregisterEvent("UPDATE_FACTION")

        local i = 1
        local faction = C_Reputation.GetFactionDataByIndex(i)
        local headerName

        while faction do
            if faction.factionID == 0 then
                -- NOTE: The 'Inactive' header holds hidden factions that aren't displayed in the default UI so break out.
                break
            end
            
            if faction.isCollapsed then
                C_Reputation.ExpandFactionHeader(i)
                table.insert(DATA.CollapsedIndexes, i)
            end

            local entry = CACHE[i]

            if not entry then
                CACHE[i] = {
                    ProgressInfo = {}
                }
                entry = CACHE[i]
            end

            -- Top level header
            if faction.isHeader and not faction.isChild then
                headerName = faction.name
            end

            entry.ID = faction.factionID
            entry.name = faction.name
            entry.headerName = headerName
            entry.isHeader = faction.isHeader
            entry.isHeaderWithRep = faction.isHeaderWithRep
            entry.isChild = faction.isChild
            entry.isAccountWide = faction.isAccountWide

            FillFactionProgressInfo(faction)

            entry.ProgressInfo.type = DATA.ProgressInfo.type
            entry.ProgressInfo.standing = DATA.ProgressInfo.standing
            entry.ProgressInfo.renownLevel = DATA.ProgressInfo.renownLevel
            entry.ProgressInfo.standingID = DATA.ProgressInfo.standingID
            entry.ProgressInfo.isCapped = DATA.ProgressInfo.isCapped
            entry.ProgressInfo.currentValue = DATA.ProgressInfo.currentValue
            entry.ProgressInfo.maxValue = DATA.ProgressInfo.maxValue
            entry.ProgressInfo.hasReward = DATA.ProgressInfo.hasReward

            CACHE.numFactions = i
            
            i = i + 1
            faction = C_Reputation.GetFactionDataByIndex(i)
        end

        for i = #DATA.CollapsedIndexes, 1, -1 do
            local collapsedIndex = DATA.CollapsedIndexes[i]
            C_Reputation.CollapseFactionHeader(collapsedIndex)
            DATA.CollapsedIndexes[i] = nil
        end

        Reputation.__cachedNumFactions = CACHE.numFactions
        Reputation:RegisterEvent("UPDATE_FACTION", CacheFactionData)
    end
    for i = 1, CACHE.numFactions do
        local entry = CACHE[i]

        if entry then
            local faction = C_Reputation.GetFactionDataByID(entry.ID)

            if faction then
                FillFactionProgressInfo(faction)

                entry.ProgressInfo.standing = DATA.ProgressInfo.standing
                entry.ProgressInfo.renownLevel = DATA.ProgressInfo.renownLevel
                entry.ProgressInfo.standingID = DATA.ProgressInfo.standingID
                entry.ProgressInfo.isCapped = DATA.ProgressInfo.isCapped
                entry.ProgressInfo.currentValue = DATA.ProgressInfo.currentValue
                entry.ProgressInfo.maxValue = DATA.ProgressInfo.maxValue
                entry.ProgressInfo.hasReward = DATA.ProgressInfo.hasReward
            end
        end
    end
end

Reputation:RegisterEvent("PLAYER_LOGIN", function(self, eventName)
    CacheFactionData()
    self:RegisterEvents(
        "MAJOR_FACTION_RENOWN_LEVEL_CHANGED", 
        "MAJOR_FACTION_UNLOCKED",
        "UPDATE_FACTION", CacheFactionData)
end)

function Reputation:GetNumFactions()
    return CACHE.numFactions
end

function Reputation:GetFactionInfoByIndex(index)
    local entry = CACHE[index]
    if entry then
        INFO.ID = entry.ID
        INFO.name = entry.name
        INFO.headerName = entry.headerName
        INFO.isHeader = entry.isHeader
        INFO.isHeaderWithRep = entry.isHeaderWithRep
        INFO.isChild = entry.isChild
        INFO.isAccountWide = entry.isAccountWide
        INFO.ProgressInfo.standing = entry.ProgressInfo.standing
        INFO.ProgressInfo.renownLevel = entry.ProgressInfo.renownLevel
        INFO.ProgressInfo.standingID = entry.ProgressInfo.standingID
        INFO.ProgressInfo.isCapped = entry.ProgressInfo.isCapped
        INFO.ProgressInfo.currentValue = entry.ProgressInfo.currentValue
        INFO.ProgressInfo.maxValue = entry.ProgressInfo.maxValue
        INFO.ProgressInfo.hasReward = entry.ProgressInfo.hasReward
        return INFO
    end
end

function Reputation:HasTrackedFactions()
    for i = 1, self:GetNumFactions() do
        local faction = self:GetFactionInfoByIndex(i)
        if faction and IsTrackedFaction(faction.ID) then
            return true
        end
    end
    return false
end

function Reputation:IterableTrackedFactionsInfo()
    local i = 0
    local n = self:GetNumFactions()
    return function()
        i = i + 1
        while i <= n do
            local faction = self:GetFactionInfoByIndex(i)
            if faction and IsTrackedFaction(faction.ID) then
                return faction, faction.ProgressInfo
            end
            i = i + 1
        end
    end
end