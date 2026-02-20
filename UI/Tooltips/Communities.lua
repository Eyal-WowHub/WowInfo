local _, addon = ...
local Communities = addon:GetObject("Communities")
local Tooltip = addon:NewTooltip("Communities", "Friends")

local MEMBERS_FORMAT = "|cff20ff20%d|r (|cffa0a0a0%d|r)"

Tooltip.target = {
    button = GuildMicroButton,
    onEnter = function()
        local totalCommunities = Communities:GetTotalCommunities()
        if totalCommunities == 0 then return end

        for community in Communities:IterableCommunitiesInfo() do
            if community.onlineCount > 1 then
                Tooltip
                    :SetDoubleLine(community.name, MEMBERS_FORMAT:format(community.onlineCount, community.totalCount))
                    :ToHeader()
            end
        end
    end
}
