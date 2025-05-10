local _, addon = ...
local Friends = addon:GetObject("Friends")
local GuildFriends = addon:NewObject("GuildFriends")

local INFO = {}

local CACHE = {}

local function CacheGuildFriendsInfo()
    local onlineFriendsLookupTable = Friends:GetOnlineFriendsInfo()

    if not onlineFriendsLookupTable then
        return
    end

    local numTotal = GetNumGuildMembers()
    local i2 = 1
    local characterName, characterLevel, zoneName, online, status, classFilename, isMobile

    for i = 1, numTotal do
        characterName, _, _, characterLevel, _, zoneName, _, _, online, status, classFilename, _, _, isMobile = GetGuildRosterInfo(i)

        if characterName then
            characterName = Ambiguate(characterName, "guild")

            if onlineFriendsLookupTable[characterName] then
                if status == 1 then
                    status = 3
                elseif status == 2 then
                    status = 4
                elseif online then
                    status = 2
                else
                    status = 1
                end

                if CACHE[i2] then
                    CACHE[i2].characterName = characterName
                    CACHE[i2].characterLevel = characterLevel
                    CACHE[i2].zoneName = zoneName
                    CACHE[i2].online = online
                    CACHE[i2].status = status
                    CACHE[i2].classFilename = classFilename
                    CACHE[i2].isMobile = isMobile
                else
                    table.insert(CACHE, {
                        characterName = characterName,
                        characterLevel = characterLevel,
                        zoneName = zoneName,
                        online = online,
                        status = status,
                        classFilename = classFilename,
                        isMobile = isMobile
                    })
                end

                i2 = i2 + 1
            end
        end
    end

    for i = i2, #CACHE do
        CACHE[i] = nil
    end

    GuildFriends.__updateCache = false
end

GuildFriends:RegisterEvents(
    "PLAYER_LOGIN",
    "FRIENDLIST_UPDATE",
    "GUILD_ROSTER_UPDATE",
    "BN_FRIEND_INFO_CHANGED",
    "BN_INFO_CHANGED", 
    function(self, eventName, ...)
        local canRequestRosterUpdate = ...
        if (eventName == "GUILD_ROSTER_UPDATE" and canRequestRosterUpdate) or eventName ~= "GUILD_ROSTER_UPDATE" then
            C_GuildInfo.GuildRoster()
            self.__updateCache = true
        end
    end)

function GuildFriends:IterableGuildFriendsInfo(index)
    if self.__updateCache then
        CacheGuildFriendsInfo()
    end
    local memberInfo, sameZone, grouped
    local i = index or 0
    local n = #CACHE
    return function()
        i = i + 1
        if i <= n then
            memberInfo = CACHE[i]

            if memberInfo.zone then
                if GetRealZoneText() == memberInfo.zone then
                    sameZone = true
                else
                    sameZone = false
                end
            end

            if UnitInParty(memberInfo.characterName) or UnitInRaid(memberInfo.characterName) then
                grouped = true
            else
                grouped = false
            end

            INFO.characterName = memberInfo.characterName
            INFO.characterLevel = memberInfo.characterLevel
            INFO.classFilename = memberInfo.classFilename
            INFO.grouped = grouped
            INFO.zoneName = memberInfo.zoneName
            INFO.sameZone = sameZone
            INFO.status = memberInfo.status
            INFO.isMobile = memberInfo.isMobile

            return i, INFO
        end
    end
end

function GuildFriends:GetTotalOnlineFriends()
    local onlineGuildFriendsCounter = 0
    local onlineGuildFriendsMobileCounter = 0
    for _, friend in self:IterableGuildFriendsInfo() do
        if friend.status > 1 then
            onlineGuildFriendsCounter = onlineGuildFriendsCounter + 1
        elseif friend.isMobile then
            onlineGuildFriendsMobileCounter = onlineGuildFriendsMobileCounter + 1
        end
    end
    return onlineGuildFriendsCounter, onlineGuildFriendsMobileCounter
end

function GuildFriends:IterableOnlineFriendsInfo()
    local maxOnlineGuildFriends = self.storage:GetMaxOnlineFriends()
    local onlineGuildFriendsCounter = 0
    local i = 0
    return function()
        if maxOnlineGuildFriends <= 0 then
            return
        end
        for index, friend in self:IterableGuildFriendsInfo(i) do
            if onlineGuildFriendsCounter >= maxOnlineGuildFriends then
                return
            end
            i = index
            if friend.status > 1 then
                onlineGuildFriendsCounter = onlineGuildFriendsCounter + 1
                return friend
            end
        end
    end
end
