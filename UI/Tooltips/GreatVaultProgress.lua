local _, addon = ...
local WeeklyRewards = addon:GetObject("WeeklyRewards")
local Tooltip = addon:NewTooltip("GreatVaultProgress")

local L = addon.L

local GREAT_VAULT_UNLOCKED_REWARD_COLOR = CreateColorFromRGBHexString("8A2BE2")

Tooltip.target = {
    button = CharacterMicroButton,
    onEnter = function()
        if IsPlayerAtEffectiveMaxLevel() then
            Tooltip:AddHeader(L["Great Vault Rewards:"])
    
            if C_WeeklyRewards.HasAvailableRewards() then
                Tooltip
                    :SetLine(L["You have rewards waiting for you at the Great Vault."])
                    :SetGreenColor()
                    :ToLine()
            end
    
            for row in WeeklyRewards:IterableGreatVaultInfo() do
                Tooltip:SetLine(row.header)
                if row.index > 0 then
                    Tooltip
                        :SetColor(GREAT_VAULT_UNLOCKED_REWARD_COLOR)
                        :SetLine(row.itemLevel)
                        :SetGreenColor()
                else
                    Tooltip:SetGrayColor()
                end
                Tooltip:ToLine()
            end
        end
    end
}