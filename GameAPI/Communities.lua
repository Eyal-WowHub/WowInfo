local _, addon = ...
local Communities = addon:NewObject("Communities")

local INFO = {
    Community = {},
    Member = {}
}

local CACHE = {}

local PRESENCE_TO_STATUS = {
    [Enum.ClubMemberPresence.Offline] = 1,
    [Enum.ClubMemberPresence.Online] = 2,
    [Enum.ClubMemberPresence.OnlineMobile] = 2,
    [Enum.ClubMemberPresence.Away] = 3,
    [Enum.ClubMemberPresence.Busy] = 4,
}

local function SortByNameAscending(a, b)
    return strcmputf8i(a.name, b.name) < 0
end

local function CacheCommunitiesInfo()
    local clubs = C_Club.GetSubscribedClubs()
    if not clubs then return end

    local i2 = 1

    for _, club in ipairs(clubs) do
        if club.clubType == Enum.ClubType.Character then
            local memberIds = C_Club.GetClubMembers(club.clubId)
            local onlineCount = 0
            local totalCount = memberIds and #memberIds or 0

            if memberIds then
                for _, memberId in ipairs(memberIds) do
                    local memberInfo = C_Club.GetMemberInfo(club.clubId, memberId)
                    if memberInfo and memberInfo.presence then
                        local status = PRESENCE_TO_STATUS[memberInfo.presence]
                        if status and status > 1 then
                            onlineCount = onlineCount + 1
                        end
                    end
                end
            end

            if CACHE[i2] then
                CACHE[i2].clubId = club.clubId
                CACHE[i2].name = club.name
                CACHE[i2].onlineCount = onlineCount
                CACHE[i2].totalCount = totalCount
            else
                CACHE[i2] = {
                    clubId = club.clubId,
                    name = club.name,
                    onlineCount = onlineCount,
                    totalCount = totalCount
                }
            end

            i2 = i2 + 1
        end
    end

    for i = i2, #CACHE do
        CACHE[i] = nil
    end

    table.sort(CACHE, SortByNameAscending)

    Communities.__updateCache = false
end

Communities:RegisterEvents(
    "INITIAL_CLUBS_LOADED",
    "CLUB_MEMBER_PRESENCE_UPDATED",
    "CLUB_UPDATED",
    "CLUB_MEMBER_ADDED",
    "CLUB_MEMBER_REMOVED",
    function(self)
        self.__updateCache = true
    end)

function Communities:GetTotalCommunities()
    if self.__updateCache then
        CacheCommunitiesInfo()
    end
    return #CACHE
end

function Communities:IterableCommunitiesInfo()
    if self.__updateCache then
        CacheCommunitiesInfo()
    end
    local i = 0
    local n = #CACHE
    return function()
        i = i + 1
        if i <= n then
            local community = CACHE[i]
            INFO.Community.clubId = community.clubId
            INFO.Community.name = community.name
            INFO.Community.onlineCount = community.onlineCount
            INFO.Community.totalCount = community.totalCount
            return INFO.Community
        end
    end
end

function Communities:IterableOnlineMembersInfo(clubId)
    local memberIds = C_Club.GetClubMembers(clubId)
    local i = 0
    local n = memberIds and #memberIds or 0
    return function()
        i = i + 1
        while i <= n do
            local memberInfo = C_Club.GetMemberInfo(clubId, memberIds[i])
            if memberInfo and memberInfo.name and memberInfo.presence and not memberInfo.isSelf then
                local status = PRESENCE_TO_STATUS[memberInfo.presence]
                if status and status > 1 then
                    local classFilename
                    if memberInfo.classID then
                        classFilename = select(2, GetClassInfo(memberInfo.classID))
                    end

                    local sameZone = false
                    if memberInfo.zone then
                        sameZone = GetRealZoneText() == memberInfo.zone
                    end

                    local grouped = false
                    if UnitInParty(memberInfo.name) or UnitInRaid(memberInfo.name) then
                        grouped = true
                    end

                    INFO.Member.characterName = memberInfo.name
                    INFO.Member.characterLevel = memberInfo.level
                    INFO.Member.classFilename = classFilename
                    INFO.Member.zoneName = memberInfo.zone
                    INFO.Member.sameZone = sameZone
                    INFO.Member.status = status
                    INFO.Member.isMobile = memberInfo.presence == Enum.ClubMemberPresence.OnlineMobile
                    INFO.Member.grouped = grouped

                    return INFO.Member
                end
            end
            i = i + 1
        end
    end
end
