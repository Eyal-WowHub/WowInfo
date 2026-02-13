local _, addon = ...
local Money = addon:GetObject("Money")
local Tooltip = addon:NewTooltip("Money")

local L = addon.L

function Tooltip:AddPlayerMoneyLine()
    local charName, moneyString = Money:GetPlayerMoneyInfo()

    return
        self:SetLine(charName)
            :SetPlayerClassColor()
            :SetLine(moneyString)
            :SetHighlight()
            :ToLine()
end

function Tooltip:AddMoneyLine(text, moneyString)
    return
        self:SetLine(text)
            :SetLine(moneyString)
            :SetHighlight()
            :ToLine()
end

Tooltip.target = {
    button = MainMenuBarBackpackButton,
    onEnter = function()
        if not MainMenuBarBackpackButton:IsVisible() then return end

        Tooltip:AddHeader(L["Money:"])
    
        Tooltip:AddPlayerMoneyLine()
    
        for charName, moneyString in Money:IterableCharactersMoneyInfo() do
            Tooltip:AddMoneyLine(charName, moneyString)
        end
    
        Tooltip
            :AddEmptyLine()
            :AddMoneyLine(L["Total"], Money:GetTotalMoneyString())
            :AddEmptyLine()
    end
}