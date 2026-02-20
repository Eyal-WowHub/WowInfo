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

local function IsOnline(status)
    return status and status > 1
end

local function SortByNameAscending(a, b)
    return strcmputf8i(a.name, b.name) < 0
end

local function CacheCommunitiesInfo()
    local clubs = C_Club.GetSubscribedClubs()
    if not clubs then return end

    local i = 1

    for _, club in ipairs(clubs) do
        if club.clubType == Enum.ClubType.Character then
            C_Club.FocusMembers(club.clubId)
            local memberIds = C_Club.GetClubMembers(club.clubId)
            local onlineCount = 0
            local totalCount = memberIds and #memberIds or 0

            if not CACHE[i] then
                CACHE[i] = { Members = {} }
            end

            local entry = CACHE[i]
            local members = entry.Members

            for memberId in pairs(members) do
                members[memberId] = nil
            end

            if memberIds then
                for _, memberId in ipairs(memberIds) do
                    local memberInfo = C_Club.GetMemberInfo(club.clubId, memberId)
                    local status
                    if memberInfo and memberInfo.presence then
                        status = PRESENCE_TO_STATUS[memberInfo.presence]
                        if IsOnline(status) then
                            onlineCount = onlineCount + 1
                        end
                    end
                    members[memberId] = status or false
                end
            end

            entry.clubId = club.clubId
            entry.name = club.name
            entry.onlineCount = onlineCount
            entry.totalCount = totalCount

            i = i + 1
        end
    end

    for j = i, #CACHE do
        CACHE[j] = nil
    end

    table.sort(CACHE, SortByNameAscending)
end

local function FindCommunityByClubId(clubId)
    for i = 1, #CACHE do
        if CACHE[i].clubId == clubId then
            return CACHE[i]
        end
    end
end

local function UpdateMemberPresence(clubId, memberId, presence)
    local community = FindCommunityByClubId(clubId)
    if not community then return end

    local newStatus = PRESENCE_TO_STATUS[presence] or false
    local oldStatus = community.Members[memberId]

    if oldStatus == newStatus then return end

    community.Members[memberId] = newStatus

    local wasOnline = IsOnline(oldStatus)
    local isNowOnline = IsOnline(newStatus)

    if wasOnline ~= isNowOnline then
        community.onlineCount = community.onlineCount + (isNowOnline and 1 or -1)
    end
end

local function UpdateClubInfo(clubId)
    local clubInfo = C_Club.GetClubInfo(clubId)
    if not clubInfo or clubInfo.clubType ~= Enum.ClubType.Character then return end

    local entry = FindCommunityByClubId(clubId)
    if not entry then return end

    local memberIds = C_Club.GetClubMembers(clubId)
    local onlineCount = 0
    local totalCount = memberIds and #memberIds or 0

    local members = entry.Members
    for memberId in pairs(members) do
        members[memberId] = nil
    end

    if memberIds then
        for _, memberId in ipairs(memberIds) do
            local memberInfo = C_Club.GetMemberInfo(clubId, memberId)
            local status
            if memberInfo and memberInfo.presence then
                status = PRESENCE_TO_STATUS[memberInfo.presence]
                if IsOnline(status) then
                    onlineCount = onlineCount + 1
                end
            end
            members[memberId] = status or false
        end
    end

    entry.onlineCount = onlineCount
    entry.totalCount = totalCount
end

Communities:RegisterEvents(
    "INITIAL_CLUBS_LOADED",
    "PLAYER_LOGIN",
    "CLUB_ADDED",
    "CLUB_REMOVED",
    "CLUB_UPDATED",
    "BN_INFO_CHANGED",
    "FRIENDLIST_UPDATE",
    function()
        CacheCommunitiesInfo()
    end)

Communities:RegisterEvents(
    "CLUB_MEMBER_ADDED",
    "CLUB_MEMBER_REMOVED",
    "CLUB_MEMBERS_UPDATED",
    function(_, _, clubId)
        UpdateClubInfo(clubId)
    end)

Communities:RegisterEvent("CLUB_MEMBER_PRESENCE_UPDATED", function(_, _, clubId, memberId, presence)
    UpdateMemberPresence(clubId, memberId, presence)
end)

Communities:RegisterEvent("CLUB_MEMBER_UPDATED", function(_, _, clubId, memberId)
    local memberInfo = C_Club.GetMemberInfo(clubId, memberId)
    if memberInfo and memberInfo.presence then
        UpdateMemberPresence(clubId, memberId, memberInfo.presence)
    end
end)

function Communities:GetTotalCommunities()
    return #CACHE
end

function Communities:IterableCommunitiesInfo()
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
                if IsOnline(status) then
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
