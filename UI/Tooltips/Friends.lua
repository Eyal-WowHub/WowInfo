local _, addon = ...
local Friends = addon:GetObject("Friends")
local Tooltip = addon:NewTooltip("Friends")

local L = addon.L

local BNET_CHAR_LINE_FORMAT = "%s (%s)"

Tooltip.target = {
    button = QuickJoinToastButton,
    onEnter = function()
        if not QuickJoinToastButton:IsVisible() then return end

        local _, numWoWOnline, _, numBNetOnline = Friends:GetNumOnlineFriendsInfo()
    
        if numWoWOnline > 0 then
            Tooltip:AddFormattedHeader(L["World of Warcraft (X):"], numWoWOnline)
    
            for friend in Friends:IterableWoWFriendsInfo() do
                local charName = Tooltip:GetFormattedCharName(friend)
                charName = Tooltip:GetFormattedStatus(friend, charName)
    
                Tooltip:SetLine(charName):ToLine()
    
                if IsShiftKeyDown() and friend.zoneName then
                    Tooltip:SetLine(friend.zoneName):Indent(6)
    
                    if friend.sameZone then
                        Tooltip:SetGreenColor()
                    else
                        Tooltip:SetGrayColor()
                    end
    
                    Tooltip:ToLine()
                end
            end
        end
    
        if numBNetOnline > 0 then
            Tooltip:AddFormattedHeader(L["Battle.net (X):"], numBNetOnline)
    
            for friend in Friends:IterableBattleNetFriendsInfo() do
                local accountName = friend.accountName
                --accountName = friend.isFavorite and friend.appearOffline and Tooltip:ToGray(accountName) or accountName
                accountName = Tooltip:GetFormattedStatus(friend, accountName)
    
                if friend.characterName then
                    Tooltip:SetFormattedLine(BNET_CHAR_LINE_FORMAT, accountName, Tooltip:GetFormattedCharName(friend))
                else
                    Tooltip:SetLine(accountName)
                end
    
                Tooltip
                    :SetColor(BATTLENET_FONT_COLOR)
                    :SetLine(friend.clientProgram)
                    :SetColor(BATTLENET_FONT_COLOR)
                    :ToLine()
    
                if IsShiftKeyDown() and friend.characterName then
                    if friend.zoneName then
                        Tooltip:SetLine(friend.zoneName):Indent(6)
                        if friend.sameZone then
                            Tooltip:SetGreenColor()
                        else
                            Tooltip:SetGrayColor()
                        end
                    end
                    if friend.realmName then
                        Tooltip:SetLine(friend.realmName):Indent(friend.zoneName and 0 or 6)
                        if friend.sameRealm then
                            Tooltip:SetGreenColor()
                        else
                            Tooltip:SetGrayColor()
                        end
                    end
                    if friend.zoneName or friend.realmName then
                        Tooltip:ToLine()
                    end
                end
            end
        end
    end
}