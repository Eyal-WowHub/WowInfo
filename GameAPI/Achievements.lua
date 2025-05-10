local _, addon = ...
local Achievements = addon:NewObject("Achievements")

local CACHE = {
    Mounts = {},
    Pets = {},
    Toys = {},
    Summary = {
        CategoriesInfo = {}
    },
    GuildSummary = {
        CategoriesInfo = {}
    }
}

local SUMMARY_CATEGORIES = {                 -- ACHIEVEMENTUI_SUMMARYCATEGORIES
    92, 96, 97, 15522, 95, 168, 169, 201, 155, 15117, 15246
}

local GUILD_SUMMARY_CATEGORIES = {            -- ACHIEVEMENTUI_GUILDSUMMARYCATEGORIES
    15088, 15077, 15078, 15079, 15080, 15089
}

local MOUNTS_BASE_ACHIEVEMENT_ID = 2143     -- Leading the Cavalry
local PETS_BASE_ACHIEVEMENT_ID = 1017       -- Can I Keep Him?
local TOYBOX_BASE_ACHIEVEMENT_ID = 9670     -- Toying Around

-- I've checked Blizzard's code and it seems like GetNextAchievement returns completed as the 2nd return value
-- however, it seems to returns nil for achievements I've completed with one faction but not the other,
-- getting the progress from GetAchievementCriteriaInfo and compare the progress seems to get the correct results.
local function GetNextAchievementInfo(achievementID)
    local nextID = GetNextAchievement(achievementID)
    if nextID and GetAchievementNumCriteria(nextID) > 0 then
        local currAmount, reqAmount = select(4, GetAchievementCriteriaInfo(nextID, 1))
        local completed = currAmount == reqAmount
        local name
        if not completed then
            name = select(2, GetAchievementInfo(nextID))
        end
        return nextID, name, completed, currAmount, reqAmount
    end
    return nextID
end

local function FindAchievementInfo(baseAchievementID)
    local id = baseAchievementID
    local _, name, _, completed = GetAchievementInfo(id)
    local currAmount, reqAmount
    if completed then
        id, name, completed, currAmount, reqAmount = GetNextAchievementInfo(id)
        while id and completed do
            id, name, completed, currAmount, reqAmount = GetNextAchievementInfo(id)
        end
    elseif GetAchievementNumCriteria(id) > 0 then
        currAmount, reqAmount = select(4, GetAchievementCriteriaInfo(id, 1))
    end
    return name, currAmount, reqAmount
end

-- This is similar to AchievementFrame_GetCategoryTotalNumAchievements from Blizzard_AchievementUI
local function GetCategoryTotalNumAchievements(categoryId, guildOnly)
    local categories = guildOnly and GetGuildCategoryList() or GetCategoryList()

	-- Not recursive because we only have one deep and this saves time.
	local totalAchievements, totalCompleted = 0, 0
	local numAchievements, numCompleted = GetCategoryNumAchievements(categoryId, true)
	totalAchievements = totalAchievements + numAchievements
	totalCompleted = totalCompleted + numCompleted

	for _, id in ipairs(categories) do
        local _, parentId = GetCategoryInfo(id)
		if parentId == categoryId then
			numAchievements, numCompleted = GetCategoryNumAchievements(id, true)
			totalAchievements = totalAchievements + numAchievements
			totalCompleted = totalCompleted + numCompleted
		end
	end

	return totalAchievements, totalCompleted
end

local function CacheAchievementInfo(key, id)
    local name, currentAmount, reqAmount = FindAchievementInfo(id)
    if name then
        CACHE[key].name = name
        CACHE[key].currentAmount = currentAmount
        CACHE[key].reqAmount = reqAmount
    else
        CACHE[key].name = nil
        CACHE[key].currentAmount = 0
        CACHE[key].reqAmount = 0
    end
end

local function CacheAchievementsCategoriesSummaryInfo(guildOnly)
    local cacheKey = guildOnly and "GuildSummary" or "Summary"
    local total, completed = GetNumCompletedAchievements(guildOnly)

    CACHE[cacheKey].total = total
    CACHE[cacheKey].completed = completed

    local catInfo = CACHE[cacheKey].CategoriesInfo
    local categories = guildOnly and GUILD_SUMMARY_CATEGORIES or SUMMARY_CATEGORIES
    local categoryId, categoryName
    
    for i = 1, #categories do
        categoryId = categories[i]
        categoryName = GetCategoryInfo(categoryId)
        total, completed = GetCategoryTotalNumAchievements(categoryId, guildOnly)
        catInfo[i] = catInfo[i] or {}
        catInfo[i].name = categoryName
        catInfo[i].total = total
        catInfo[i].completed = completed
    end
end

Achievements:RegisterEvents(
    "PLAYER_LOGIN", 
    "ACHIEVEMENT_EARNED",
    function(_, eventName)
        CacheAchievementInfo("Mounts", MOUNTS_BASE_ACHIEVEMENT_ID)
        CacheAchievementInfo("Pets", PETS_BASE_ACHIEVEMENT_ID)
        CacheAchievementInfo("Toys", TOYBOX_BASE_ACHIEVEMENT_ID)
        CacheAchievementsCategoriesSummaryInfo()
        CacheAchievementsCategoriesSummaryInfo(true)
    end)

function Achievements:GetMountAchievementInfo()
    return CACHE.Mounts.name, CACHE.Mounts.currentAmount, CACHE.Mounts.reqAmount
end

function Achievements:GetPetsAchievementInfo()
    return CACHE.Pets.name, CACHE.Pets.currentAmount, CACHE.Pets.reqAmount
end

function Achievements:GetToysAchievementInfo()
    return CACHE.Toys.name, CACHE.Toys.currentAmount, CACHE.Toys.reqAmount
end

function Achievements:GetSummaryProgressInfo(guildOnly)
    local cacheKey = guildOnly and "GuildSummary" or "Summary"
    return CACHE[cacheKey].total, CACHE[cacheKey].completed
end

function Achievements:IterableCategoriesSummaryInfo(guildOnly)
    local cacheKey = guildOnly and "GuildSummary" or "Summary"
    local categories = CACHE[cacheKey].CategoriesInfo
    local category
    local i = 0
    local n = #categories
    return function()
        i = i + 1
        if i <= n then
            category = categories[i]
            return category.name, category.total, category.completed
        end
    end
end