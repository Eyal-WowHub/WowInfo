local _, addon = ...
local PvP = addon:NewObject("PvP")

local INFO = {
    Honor = {},
    Rated = {
        Bracket = {},
        Conquest = {}
    }
}

local DATA = {
    SeasonState = 0
}

local ARENA_SEASON_STATE = {
    NoSeason = 0,           -- NO_ARENA_SEASON
    OffSeason = 1,          -- SEASON_STATE_OFFSEASON
    Preseason = 2,          -- SEASON_STATE_PRESEASON
    Active = 3,             -- SEASON_STATE_ACTIVE
    Disabled = 4            -- SEASON_STATE_DISABLED
}

local BRACKETS_NAMES = {      -- CONQUEST_SIZE_STRINGS
    ARENA .. ": " .. RATED_SOLO_SHUFFLE_SIZE, 
    ARENA .. ": " .. ARENA_2V2, 
    ARENA .. ": " .. ARENA_3V3, 
    BATTLEGROUNDS .. ": " .. RATED_BG_BLITZ_SIZE, 
    BATTLEGROUNDS .. ": " .. BATTLEGROUND_10V10 
}

local BRACKETS_INDEXES = {    -- CONQUEST_BRACKET_INDEXES
    7,  -- Solo Shuffle
    1,  -- 2v2
    2,  -- 3v3
    9,  -- Blitz 
    4   -- 10v10
}

local function GetRatedPvPSeasonState(isRatedPvPDisabled)
    local season = GetCurrentArenaSeason()
    if season == ARENA_SEASON_STATE.NoSeason then
        if isRatedPvPDisabled then
            return ARENA_SEASON_STATE.Preseason
        else
            return ARENA_SEASON_STATE.OffSeason
        end
    else
        if isRatedPvPDisabled then
            return ARENA_SEASON_STATE.Disabled
        else
            return ARENA_SEASON_STATE.Active
        end
    end
end

local function GetSeasonTierInfo(bracketTierID)
    local tierInfo = C_PvP.GetPvpTierInfo(bracketTierID)
    if tierInfo then
        local ascendTierInfo = tierInfo.ascendTier and C_PvP.GetPvpTierInfo(tierInfo.ascendTier)
        local ascendTierName

        if ascendTierInfo then
            ascendTierName = PVPUtil.GetTierName(ascendTierInfo.pvpTierEnum)
        end

        return PVPUtil.GetTierName(tierInfo.pvpTierEnum), tierInfo.tierIconID, ascendTierName
    end
end

PvP:RegisterEvents(
    "PLAYER_LOGIN",
    "PLAYER_SPECIALIZATION_CHANGED",
    "PVP_TYPES_ENABLED",
    --"PVP_RATED_STATS_UPDATE",
    function(_, eventName, ...) 
        if eventName == "PLAYER_LOGIN" then
            RequestRatedInfo()
            RequestPVPOptionsEnabled()
        elseif eventName == "PLAYER_SPECIALIZATION_CHANGED" then
            RequestRatedInfo()
        elseif eventName == "PVP_TYPES_ENABLED" then
            local _, ratedBgs, ratedArenas, ratedSoloShuffle, ratedBGBlitz = ...
            local isRatedPvPDisabled = not ratedBgs and not ratedArenas and not ratedSoloShuffle and not ratedBGBlitz 
            DATA.SeasonState = GetRatedPvPSeasonState(isRatedPvPDisabled)
        end        
    end)

function PvP:GetHonorProgressInfo()
    INFO.Honor.currentValue = UnitHonor("player")
    INFO.Honor.maxValue = UnitHonorMax("player")
    INFO.Honor.level = UnitHonorLevel("player")
    return INFO.Honor
end

function PvP:GetConquestProgressInfo()
    INFO.Rated.Conquest.currentValue = nil
    INFO.Rated.Conquest.maxValue = nil
    INFO.Rated.Conquest.isCapped = false
    INFO.Rated.Conquest.displayType = nil

    if DATA.SeasonState == ARENA_SEASON_STATE.Active or DATA.SeasonState == ARENA_SEASON_STATE.OffSeason then
        local currency = C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CONQUEST_CURRENCY_ID)

        local currentValue = currency.totalEarned
        local maxValue = currency.maxQuantity
        local isCapped = currentValue >= maxValue

        local weeklyProgress = C_WeeklyRewards.GetConquestWeeklyProgress()
	    local displayType = weeklyProgress.displayType
        
        INFO.Rated.Conquest.currentValue = currentValue
        INFO.Rated.Conquest.maxValue = maxValue
        INFO.Rated.Conquest.isCapped = isCapped
        INFO.Rated.Conquest.displayType = Enum.ConquestProgressBarDisplayType

        return INFO.Rated.Conquest
    end
end

function PvP:IsPreseason()
    return DATA.SeasonState == ARENA_SEASON_STATE.Preseason
end

function PvP:IterableBracketInfo()
    local i = 0
    local n = #BRACKETS_NAMES
    return function()
        i = i + 1
        if i <= n then
            local name = BRACKETS_NAMES[i]
            local bracketIndex = BRACKETS_INDEXES[i]
            local rating, _, _, _, _, weeklyPlayed, weeklyWon,_, _, pvpTier = GetPersonalRatedInfo(bracketIndex)
            local tierName, tierIconID, nextTierName = GetSeasonTierInfo(pvpTier)
            local bracket = INFO.Rated.Bracket[i]

            if not bracket then
                INFO.Rated.Bracket[i] = {}
                bracket = INFO.Rated.Bracket[i]
            end

            bracket.name = name
            bracket.rating = rating
            bracket.weeklyPlayed = weeklyPlayed
            bracket.weeklyWon = weeklyWon
            bracket.weeklyLost = weeklyPlayed - weeklyWon
            bracket.tierName = tierName
            bracket.tierIcon = tierIconID
            bracket.nextTierName = nextTierName

            return bracket
        end
    end
end

function PvP:TryLoadSeasonItemReward()
	local achievementID = C_PvP.GetPVPSeasonRewardAchievementID()

	if achievementID then
		while true do
			local completed = select(4, GetAchievementInfo(achievementID))

			if not completed then
				break
			end

			local supercedingAchievements = C_AchievementInfo.GetSupercedingAchievements(achievementID)
			
            if not supercedingAchievements[1] then
				break
			end

			achievementID = supercedingAchievements[1]
		end
	end

    if not achievementID or GetAchievementNumCriteria(achievementID) == 0 then
		return
	end

    local criteriaString, _, completed, quantity, reqQuantity = GetAchievementCriteriaInfo(achievementID, 1)
    
    if criteriaString and not completed then
        local rewardItemID = C_AchievementInfo.GetRewardItemID(achievementID)

        if rewardItemID then
            local itemReward = Item:CreateFromItemID(rewardItemID)

            if itemReward then
                if not self.__itemDataLoadedCancelFunc then
                    self.__itemDataLoadedCancelFunc = function()
                        local itemName = itemReward:GetItemName()
                        
                        if itemName then
                            local itemQuality = itemReward:GetItemQuality()
                            local itemIcon = itemReward:GetItemIcon()
                            local progress =  quantity / reqQuantity
                            
                            self:TriggerEvent("WOWINFO_PVP_SEASON_REWARD", itemName, itemQuality, progress, itemIcon)
                        end
                    end
                end

                itemReward:ContinueWithCancelOnItemLoad(self.__itemDataLoadedCancelFunc)
            end
        end
    end
end

function PvP:CancelSeasonItemReward()
    if self.__itemDataLoadedCancelFunc then
		self.__itemDataLoadedCancelFunc()
		self.__itemDataLoadedCancelFunc = nil
	end
end