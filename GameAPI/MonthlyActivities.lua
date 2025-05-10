local _, addon = ...
local MonthlyActivities = addon:NewObject("MonthlyActivities")

local INFO = {}

local CACHE = {}

local MONTHLY_ACTIVITIES_MONTH_NAMES = {
	MONTH_JANUARY,
	MONTH_FEBRUARY,
	MONTH_MARCH,
	MONTH_APRIL,
	MONTH_MAY,
	MONTH_JUNE,
	MONTH_JULY,
	MONTH_AUGUST,
	MONTH_SEPTEMBER,
	MONTH_OCTOBER,
	MONTH_NOVEMBER,
	MONTH_DECEMBER,
}

local MONTHLY_ACTIVITIES_DAYS = MONTHLY_ACTIVITIES_DAYS

local function AreMonthlyActivitiesRestricted()
	return IsTrialAccount() or IsVeteranTrialAccount()
end

local function HasPendingReward(activitiesInfo, pendingRewards, thresholdOrderIndex)
    for _, reward in pairs(pendingRewards) do
        if reward.activityMonthID == activitiesInfo.activePerksMonth and reward.thresholdOrderIndex == thresholdOrderIndex then
            return true
        end
    end
    return false
end

local GetMonthlyActivitiesTimeInfo
do
    local MonthlyActivitiesTimeLeftFormatter = CreateFromMixins(SecondsFormatterMixin)
    MonthlyActivitiesTimeLeftFormatter:Init(0, SecondsFormatter.Abbreviation.OneLetter, false, true)
    MonthlyActivitiesTimeLeftFormatter:SetStripIntervalWhitespace(true)

    function MonthlyActivitiesTimeLeftFormatter:GetMinInterval(seconds)
        return SecondsFormatter.Interval.Minutes
    end

    function MonthlyActivitiesTimeLeftFormatter:GetDesiredUnitCount(seconds)
        return 2
    end

    function GetMonthlyActivitiesTimeInfo(displayMonthName, secondsRemaining)
        local time = MonthlyActivitiesTimeLeftFormatter:Format(secondsRemaining)
        local timeString = MONTHLY_ACTIVITIES_DAYS:format(time)
        local monthString

        if displayMonthName and #displayMonthName > 0 then
            monthString = displayMonthName
        else
            local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()
            monthString = MONTHLY_ACTIVITIES_MONTH_NAMES[currentCalendarTime.month]
        end

        return monthString, timeString
    end
end

local function CacheActivitiesInfo()
    local activitiesInfo = C_PerksActivities.GetPerksActivitiesInfo()
    local pendingRewards = C_PerksProgram.GetPendingChestRewards()

    local itemReward, pendingReward
    local thresholdMax = 0
    for _, thresholdInfo in pairs(activitiesInfo.thresholds) do
        thresholdInfo.pendingReward = HasPendingReward(activitiesInfo, pendingRewards, thresholdInfo.thresholdOrderIndex)
        if thresholdInfo.requiredContributionAmount > thresholdMax then
            thresholdMax = thresholdInfo.requiredContributionAmount
            itemReward = thresholdInfo.itemReward and Item:CreateFromItemID(thresholdInfo.itemReward) or nil
            pendingReward = thresholdInfo.pendingReward
        end
    end

    -- Prevent divide by zero below
    if thresholdMax == 0 then
        thresholdMax = 1000
    end

    local earnedThresholdAmount = 0
    for _, activity in pairs(activitiesInfo.activities) do
        if activity.completed then
            earnedThresholdAmount = earnedThresholdAmount + activity.thresholdContributionAmount
        end
    end
    earnedThresholdAmount = math.min(earnedThresholdAmount, thresholdMax)

    CACHE.itemReward = itemReward
    CACHE.pendingReward = pendingReward
    CACHE.thresholdMax = thresholdMax
    CACHE.earnedThresholdAmount = earnedThresholdAmount
    CACHE.displayMonthName = activitiesInfo.displayMonthName
    CACHE.secondsRemaining = activitiesInfo.secondsRemaining
end

MonthlyActivities:RegisterEvents(
    "PLAYER_LOGIN",
    "CHEST_REWARDS_UPDATED_FROM_SERVER",
    "PERKS_ACTIVITIES_TRACKED_LIST_CHANGED",
    "PERKS_ACTIVITIES_UPDATED",
    "PERKS_ACTIVITY_COMPLETED", 
    function(_, eventName)
        CacheActivitiesInfo()
    end)

function MonthlyActivities:GetProgressInfo()
    if AreMonthlyActivitiesRestricted() then
        return nil
    end

    local monthString, timeString = GetMonthlyActivitiesTimeInfo(CACHE.displayMonthName, CACHE.secondsRemaining)

    INFO.hasReward = CACHE.itemReward ~= nil
    INFO.hasRewardPending = CACHE.pendingReward
    INFO.maxValue = CACHE.thresholdMax
    INFO.currentValue = CACHE.earnedThresholdAmount
    INFO.monthString = monthString
    INFO.timeString = timeString

    return INFO
end

function MonthlyActivities:TryLoadItemReward()
    local itemReward = CACHE.itemReward

    if itemReward then
        if not self.__itemDataLoadedCancelFunc then
            self.__itemDataLoadedCancelFunc = function()
                local itemName = itemReward:GetItemName()
                
                if itemName then
                    local itemColor = itemReward:GetItemQualityColor()
                    local itemIcon = itemReward:GetItemIcon()
                    local progress =  CACHE.earnedThresholdAmount / CACHE.thresholdMax

                    itemColor = itemColor and itemColor.color or NORMAL_FONT_COLOR

                    self:TriggerEvent("WOWINFO_MONTHLY_ACTIVITIES_REWARD", itemName, itemColor, progress, itemIcon)
                end
            end
        end

        itemReward:ContinueWithCancelOnItemLoad(self.__itemDataLoadedCancelFunc)
    end
end

function MonthlyActivities:CancelItemReward()
    if self.__itemDataLoadedCancelFunc then
		self.__itemDataLoadedCancelFunc()
		self.__itemDataLoadedCancelFunc = nil
	end
end