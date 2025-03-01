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

local function GetActivityInfo(type)
    local activityInfo
    local minThreshold
    for _, currentActivityInfo in ipairs(C_WeeklyRewards.GetActivities(type)) do
        activityInfo = currentActivityInfo
        activityInfo.minThreshold = minThreshold or currentActivityInfo.threshold
        if currentActivityInfo.progress <= currentActivityInfo.threshold then
            break
        end
        minThreshold = currentActivityInfo.threshold
    end
    return activityInfo
end

local function CacheWeeklyRewardProgressInfo(type)
    if CACHE[type] then
        local activityInfo = GetActivityInfo(type)

        CACHE[type].thresholdString = nil
        CACHE[type].progress = nil
        CACHE[type].index = nil

        if activityInfo then
            local thresholdString

            if activityInfo.type == Enum.WeeklyRewardChestThresholdType.Raid then
                if activityInfo.raidString then
                    thresholdString = activityInfo.raidString
                else
                    thresholdString = WEEKLY_REWARDS_THRESHOLD_RAID
                end
            elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.Activities then
                thresholdString = WEEKLY_REWARDS_THRESHOLD_DUNGEONS
            elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
                thresholdString = WEEKLY_REWARDS_THRESHOLD_PVP
            elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.World then
                thresholdString = WEEKLY_REWARDS_THRESHOLD_WORLD
            end

            if thresholdString then
                CACHE[type].header = thresholdString:format(activityInfo.threshold)
                CACHE[type].progress = activityInfo.progress
                CACHE[type].index = activityInfo.index and activityInfo.progress >= activityInfo.minThreshold and activityInfo.index or 0
            end
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

function WeeklyRewards:GetProgressInfo(type)
    local data = CACHE[type]
    if data then
        INFO[type].header = data.header
        INFO[type].progress = data.progress
        INFO[type].index = data.index
        return INFO[type]
    end
end

function WeeklyRewards:IterableGreatVaultInfo()
    local i = 0
    local n = #GREAT_VAULT_ORDER_MAP
    return function()
        i = i + 1
        if i <= n then
            local type = GREAT_VAULT_ORDER_MAP[i]
            return self:GetProgressInfo(type)
        end
    end
end