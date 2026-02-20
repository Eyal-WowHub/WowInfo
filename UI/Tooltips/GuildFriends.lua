local _, addon = ...
local GuildFriends = addon:GetObject("GuildFriends")
local Tooltip = addon:NewTooltip("GuildFriends", "Friends")

local L = addon.L

local MEMBERS_FORMAT = "|cff20ff20%d|r (|cffa0a0a0%d|r)"

Tooltip.target = {
    button = GuildMicroButton,
    onEnter = function()
        local numTotalGuildMembers, numOnlineGuildMembers = GetNumGuildMembers()
    
        if numTotalGuildMembers > 0 then
            local guildName = GetGuildInfo("player")

            Tooltip
                :SetDoubleLine(guildName or L["Guild:"], MEMBERS_FORMAT:format(numOnlineGuildMembers, numTotalGuildMembers))
                :ToHeader()
    
            for friend in GuildFriends:IterableOnlineFriendsInfo() do
                local charName = Tooltip:GetFormattedCharName(friend)
                charName = Tooltip:GetFormattedStatus(friend, charName)
    
                Tooltip:SetLine(charName)
    
                if IsShiftKeyDown() and friend.zoneName then
                    Tooltip:SetLine(friend.zoneName)
    
                    if friend.sameZone then
                        Tooltip:SetGreenColor()
                    else
                        Tooltip:SetGrayColor()
                    end
                end
    
                Tooltip:ToLine()
            end
        end
    end
}