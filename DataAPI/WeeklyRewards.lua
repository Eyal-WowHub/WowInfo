local _, addon = ...
local WeeklyRewards = addon:NewObject("WeeklyRewards")

local INFO = {
    [Enum.WeeklyRewardChestThresholdType.Raid] = {},
    [Enum.WeeklyRewardChestThresholdType.Activities] = {},
    [Enum.WeeklyRewardChestThresholdType.RankedPvP] = {},
    [Enum.WeeklyRewardChestThresholdType.World] = {}
}

local CACHE = {
    [Enum.WeeklyRewardChestThresholdType.Raid] = {},
    [Enum.WeeklyRewardChestThresholdType.Activities] = {},
    [Enum.WeeklyRewardChestThresholdType.RankedPvP] = {},
    [Enum.WeeklyRewardChestThresholdType.World] = {}
}

local GREAT_VAULT_ORDER_MAP = {
    Enum.WeeklyRewardChestThresholdType.Raid,
    Enum.WeeklyRewardChestThresholdType.Activities,
    Enum.WeeklyRewardChestThresholdType.World
}

local function GetUnlockedActivityInfo(activityType)
    local prevActivityInfo = nil
    for _, activityInfo in ipairs(C_WeeklyRewards.GetActivities(activityType)) do
        prevActivityInfo = prevActivityInfo or activityInfo
        if activityInfo.progress < activityInfo.threshold then
            break
        end
        prevActivityInfo = activityInfo
    end
    return prevActivityInfo
end

local function IsCompletedAtHeroicLevel(activityTierID)
	local difficultyID = C_WeeklyRewards.GetDifficultyIDForActivityTier(activityTierID);
	return difficultyID == DifficultyUtil.ID.DungeonHeroic;
end

local function CacheWeeklyRewardProgressInfo(activityType)
    if not CACHE[activityType] then return end

    CACHE[activityType].header = nil
    CACHE[activityType].levelString = nil
    CACHE[activityType].progress = nil
    CACHE[activityType].index = nil

    local activityInfo = GetUnlockedActivityInfo(activityType)
    if not activityInfo then return end

    local thresholdString, levelString
    
    local itemLevel = 0
    local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activityInfo.id)

    if itemLink then
		itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink) or 0
	end

    if activityInfo.type == Enum.WeeklyRewardChestThresholdType.Raid then
        thresholdString = activityInfo.raidString or WEEKLY_REWARDS_THRESHOLD_RAID
        levelString = DifficultyUtil.GetDifficultyName(activityInfo.level)
    elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.Activities then
        thresholdString = WEEKLY_REWARDS_THRESHOLD_DUNGEONS
        if IsCompletedAtHeroicLevel(activityInfo.activityTierID) then
            levelString = WEEKLY_REWARDS_HEROIC
        else
            levelString = WEEKLY_REWARDS_MYTHIC:format(activityInfo.level)
        end
    elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
        thresholdString = WEEKLY_REWARDS_THRESHOLD_PVP
        levelString = PVPUtil.GetTierName(activityInfo.level)
    elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.World then
        thresholdString = WEEKLY_REWARDS_THRESHOLD_WORLD
        levelString = GREAT_VAULT_WORLD_TIER:format(activityInfo.level)
    end

    if thresholdString then
        CACHE[activityType].header = thresholdString:format(activityInfo.threshold)
        CACHE[activityType].levelString = levelString
        CACHE[activityType].progress = activityInfo.progress
        CACHE[activityType].index = activityInfo.progress >= activityInfo.threshold and activityInfo.index or 0
        if not CACHE[activityType].itemLevel or itemLevel > CACHE[activityType].itemLevel then
            CACHE[activityType].itemLevel = itemLevel
        end
    end
end

WeeklyRewards:RegisterEvents(
    "PLAYER_LOGIN", 
    "WEEKLY_REWARDS_UPDATE", 
    function(_, eventName)
        CacheWeeklyRewardProgressInfo(Enum.WeeklyRewardChestThresholdType.Raid)
        CacheWeeklyRewardProgressInfo(Enum.WeeklyRewardChestThresholdType.Activities)
        CacheWeeklyRewardProgressInfo(Enum.WeeklyRewardChestThresholdType.RankedPvP)
        CacheWeeklyRewardProgressInfo(Enum.WeeklyRewardChestThresholdType.World)
    end)

function WeeklyRewards:GetProgressInfo(activityType)
    local data = CACHE[activityType]
    if data then
        INFO[activityType].header = data.header
        INFO[activityType].levelString = data.levelString
        INFO[activityType].progress = data.progress
        INFO[activityType].index = data.index
        INFO[activityType].itemLevel = data.itemLevel
        return INFO[activityType]
    end
end

function WeeklyRewards:IterableGreatVaultInfo()
    local i = 0
    local n = #GREAT_VAULT_ORDER_MAP
    return function()
        i = i + 1
        if i <= n then
            local activityType = GREAT_VAULT_ORDER_MAP[i]
            return self:GetProgressInfo(activityType)
        end
    end
end