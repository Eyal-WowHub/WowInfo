local _, addon = ...
local Quests = addon:NewObject("Quests")

local INFO = {
    Quests = {},
    Story = {},
    Campaign = {}
}

local CACHE = {
    Quests = {},
    Story = {},
    Campaign = {}
}

local EMPTY_CHAPTERS = {}

local function IterableQuestInfo()
    local i = 0
    local n = C_QuestLog.GetNumQuestLogEntries()
    return function()
        i = i + 1
        while i <= n do
            local questInfo = C_QuestLog.GetInfo(i)
            if questInfo and not questInfo.isHeader and not questInfo.isHidden and QuestHasPOIInfo(questInfo.questID) then
                return questInfo, questInfo.questID
            end
            i = i + 1
        end
    end
end

local function CacheQuestLogInfo()
    local numQuests, completedQuests = 0, 0

    for _, questID in IterableQuestInfo() do
        numQuests = numQuests + 1
        if C_QuestLog.IsComplete(questID) then
            completedQuests = completedQuests + 1
        end
    end

    CACHE.Quests.total = numQuests
    CACHE.Quests.totalCompleted = completedQuests
    CACHE.Quests.totalIncompleted = numQuests - completedQuests
end

local function CacheCampaignInfo()
    CACHE.Campaign.ID = nil
    CACHE.Campaign.title = nil
    CACHE.Campaign.chapterIDs = nil
    CACHE.Campaign.numChapters = 0
    CACHE.Campaign.numCompleted = 0
    CACHE.Campaign.isCompleted = false

    -- NOTE: When logging in for the first time, C_QuestLog.GetInfo does not return any data for campaignID. 
    -- To retrieve this data, you need to call C_QuestLog.UpdateCampaignHeaders. 
    -- However, this function should be called after the QUEST_POI_UPDATE event has fired. 
    -- Calling it before this event will result in no updates being made.
    C_QuestLog.UpdateCampaignHeaders()

    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local questInfo = C_QuestLog.GetInfo(i)
        local campaignID = questInfo.campaignID

        if campaignID and questInfo.isHeader and not questInfo.useMinimalHeader then
            local chapterIDs = EMPTY_CHAPTERS
            local completedChapters = 0
            local state = C_CampaignInfo.GetState(campaignID)

            if state == Enum.CampaignState.InProgress or state == Enum.CampaignState.Stalled then
                chapterIDs = C_CampaignInfo.GetChapterIDs(campaignID)
                for _, chapterID in ipairs(chapterIDs) do
                    if C_QuestLine.IsComplete(chapterID) then
                        completedChapters = completedChapters + 1
                    end
                end
            elseif state == Enum.CampaignState.Invalid then
                campaignID = nil
            end
            
            CACHE.Campaign.ID = campaignID
            CACHE.Campaign.title = questInfo.title
            CACHE.Campaign.chapterIDs = chapterIDs
            CACHE.Campaign.numChapters = #chapterIDs
            CACHE.Campaign.numCompleted = completedChapters
            CACHE.Campaign.isCompleted = state == Enum.CampaignState.Complete 
        end
    end
end

local function CacheZoneStoryInfo()
    CACHE.Story.ID = nil
    CACHE.Story.title = nil
    CACHE.Story.numCriteria = 0
    CACHE.Story.numCompleted = 0
    CACHE.Story.isCompleted = false

    local mapID = C_Map.GetBestMapForUnit("player")

    if mapID then
        local storyAchievementID, storyMapID = C_QuestLog.GetZoneStoryInfo(mapID)

        if storyAchievementID then
            local mapInfo = C_Map.GetMapInfo(storyMapID)
            local numCriteria = GetAchievementNumCriteria(storyAchievementID)
            local numCompletedCriteria = 0

            for i = 1, numCriteria do
                local _, _, completed = GetAchievementCriteriaInfo(storyAchievementID, i)
                if completed then
                    numCompletedCriteria = numCompletedCriteria + 1
                end
            end

            CACHE.Story.ID = storyAchievementID
            CACHE.Story.title = mapInfo.name
            CACHE.Story.numCriteria = numCriteria
            CACHE.Story.numCompleted = numCompletedCriteria
            CACHE.Story.isCompleted = numCriteria == numCompletedCriteria
        end
    end
end

Quests:RegisterEvents(
    "PLAYER_LOGIN",
    "QUEST_ACCEPTED",
    "QUEST_REMOVED", 
    "QUEST_TURNED_IN",
    "QUEST_POI_UPDATE",
    "ZONE_CHANGED",
    "ZONE_CHANGED_NEW_AREA",
    "UNIT_QUEST_LOG_CHANGED", 
    function(_, eventName, ...)
        if eventName == "ZONE_CHANGED" or eventName == "ZONE_CHANGED_NEW_AREA" then
            CacheZoneStoryInfo()
        else
            if eventName == "UNIT_QUEST_LOG_CHANGED" then
                local arg1 = ...
                if arg1 ~= "player" then return end
            end
            CacheZoneStoryInfo()
            CacheQuestLogInfo()
            CacheCampaignInfo()
        end
    end)

do
    local QuestResetTimeSecondsFormatter = CreateFromMixins(SecondsFormatterMixin)
    QuestResetTimeSecondsFormatter:Init(SECONDS_PER_MIN, SecondsFormatter.Abbreviation.Truncate, false)

    function Quests:GetResetTimeString()
        return QuestResetTimeSecondsFormatter:Format(GetQuestResetTime())
    end
end

function Quests:GetQuestLogInfo()
    INFO.Quests.total = CACHE.Quests.total
    INFO.Quests.totalCompleted = CACHE.Quests.totalCompleted
    INFO.Quests.totalIncompleted = CACHE.Quests.totalIncompleted
    return INFO.Quests
end

function Quests:GetCampaignInfo()
    INFO.Campaign.ID = CACHE.Campaign.ID
    INFO.Campaign.title = CACHE.Campaign.title
    INFO.Campaign.chapterIDs = CACHE.Campaign.chapterIDs
    INFO.Campaign.numChapters = CACHE.Campaign.numChapters
    INFO.Campaign.numCompleted = CACHE.Campaign.numCompleted
    INFO.Campaign.isCompleted = CACHE.Campaign.isCompleted
    return INFO.Campaign
end

function Quests:IterableCampaignChaptersInfo()
    local currentChapterID
    local i = 0
    local campaignID = CACHE.Campaign.ID
    local chapterIDs = CACHE.Campaign.chapterIDs
    local n = chapterIDs and #chapterIDs or 0
    return function()
        if not campaignID then
            return
        elseif not currentChapterID then
            currentChapterID = C_CampaignInfo.GetCurrentChapterID(campaignID)
        end
        i = i + 1
        while i <= n do
            local chapterID = chapterIDs[i]
            local chapterInfo = C_CampaignInfo.GetCampaignChapterInfo(chapterID)
            if chapterInfo and chapterInfo.name then
                local isCompleted = C_QuestLine.IsComplete(chapterID)
                return chapterInfo.name, chapterID == currentChapterID, isCompleted
            end
            i = i + 1
        end
    end
end

function Quests:GetZoneStoryInfo()
    INFO.Story.ID = CACHE.Story.ID
    INFO.Story.title = CACHE.Story.title
    INFO.Story.numCriteria = CACHE.Story.numCriteria
    INFO.Story.numCompleted = CACHE.Story.numCompleted
    INFO.Story.isCompleted = CACHE.Story.isCompleted
    return INFO.Story 
end

function Quests:IterableZoneStoryChaptersInfo()
    local storyAchievementID = CACHE.Story.ID
    local numCriteria = GetAchievementNumCriteria(storyAchievementID)
    local currentCriteria
    local i = 0
    local n = numCriteria or 0
    return function()
        if not storyAchievementID then
            return
        end
        i = i + 1
        if i <= n then
            local title, _, completed = GetAchievementCriteriaInfo(storyAchievementID, i)
            if not currentCriteria and not completed then
                currentCriteria = i
            end
            return title, currentCriteria == i, completed
        end
    end
end