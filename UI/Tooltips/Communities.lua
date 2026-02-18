local _, addon = ...
local Communities = addon:GetObject("Communities")
local Tooltip = addon:NewTooltip("Communities", "Friends")

local L = addon.L

Tooltip.target = {
    button = GuildMicroButton,
    onEnter = function()
        local totalCommunities = Communities:GetTotalCommunities()
        if totalCommunities == 0 then return end

        Tooltip:AddHeader(L["Communities:"])

        for community in Communities:IterableCommunitiesInfo() do
            Tooltip
                :SetDoubleLine(community.name, L["X Online"]:format(community.onlineCount))
                :ToHeader()

            if IsShiftKeyDown() and community.onlineCount > 0 then
                for member in Communities:IterableOnlineMembersInfo(community.clubId) do
                    local charName = Tooltip:GetFormattedCharName(member)
                    charName = Tooltip:GetFormattedStatus(member, charName)

                    Tooltip:SetLine(charName)

                    if member.zoneName then
                        Tooltip:SetLine(member.zoneName)

                        if member.sameZone then
                            Tooltip:SetGreenColor()
                        else
                            Tooltip:SetGrayColor()
                        end
                    end

                    Tooltip:ToLine()
                end
            end
        end
    end
}
