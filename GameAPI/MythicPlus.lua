local _, addon = ...
local MythicPlus = addon:NewObject("MythicPlus")

local INFO = {
    Keystone = {},
    Dungeon = {}
}

local CACHE = {
    score = 0,
    scoreColor = nil,
    dungeons = {},
    weeklyRunCount = 0
}

local function SortByScoreDescending(a, b)
    if a.score ~= b.score then
        return a.score > b.score
    end
    return strcmputf8i(a.name, b.name) > 0
end

local function CacheDungeonData()
    CACHE.score = C_ChallengeMode.GetOverallDungeonScore() or 0
    CACHE.scoreColor = C_ChallengeMode.GetDungeonScoreRarityColor(CACHE.score)

    local maps = C_ChallengeMode.GetMapTable()
    if not maps then return end

    local dungeons = CACHE.dungeons

    for i, mapID in ipairs(maps) do
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        local inTimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)

        local level = 0
        local dungeonScore = 0

        if inTimeInfo and overtimeInfo then
            local inTimeScoreIsBetter = inTimeInfo.dungeonScore > overtimeInfo.dungeonScore
            level = inTimeScoreIsBetter and inTimeInfo.level or overtimeInfo.level
            dungeonScore = inTimeScoreIsBetter and inTimeInfo.dungeonScore or overtimeInfo.dungeonScore
        elseif inTimeInfo or overtimeInfo then
            level = inTimeInfo and inTimeInfo.level or overtimeInfo.level
            dungeonScore = inTimeInfo and inTimeInfo.dungeonScore or overtimeInfo.dungeonScore
        end

        if dungeons[i] then
            dungeons[i].name = name
            dungeons[i].level = level
            dungeons[i].score = dungeonScore
        else
            dungeons[i] = {
                name = name,
                level = level,
                score = dungeonScore
            }
        end
    end

    for i = #maps + 1, #dungeons do
        dungeons[i] = nil
    end

    table.sort(dungeons, SortByScoreDescending)
end

local function CacheWeeklyRunCount()
    local runs = C_MythicPlus.GetRunHistory(false, false, true)
    local count = 0
    for _, run in ipairs(runs) do
        if run.thisWeek and run.completed then
            count = count + 1
        end
    end
    CACHE.weeklyRunCount = count
end

MythicPlus:RegisterEvents(
    "PLAYER_LOGIN",
    "CHALLENGE_MODE_MAPS_UPDATE",
    "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE",
    function(_, eventName)
        if eventName == "PLAYER_LOGIN" then
            C_MythicPlus.RequestMapInfo()
            C_MythicPlus.RequestCurrentAffixes()
        end
        CacheDungeonData()
        CacheWeeklyRunCount()
    end)

function MythicPlus:GetKeystoneInfo()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    if not level then return nil end

    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    if not mapID then return nil end

    local name = C_ChallengeMode.GetMapUIInfo(mapID)

    INFO.Keystone.name = name
    INFO.Keystone.level = level

    return INFO.Keystone
end

function MythicPlus:GetOverallScore()
    if CACHE.score > 0 then
        return CACHE.score, CACHE.scoreColor
    end
    return nil
end

function MythicPlus:GetWeeklyRunCount()
    return CACHE.weeklyRunCount
end

function MythicPlus:IterableSeasonBestInfo()
    local i = 0
    local n = #CACHE.dungeons
    return function()
        i = i + 1
        if i <= n then
            local dungeon = CACHE.dungeons[i]
            INFO.Dungeon.name = dungeon.name
            INFO.Dungeon.level = dungeon.level
            INFO.Dungeon.score = dungeon.score
            return INFO.Dungeon
        end
    end
end
