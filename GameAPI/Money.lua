local _, addon = ...
local Money = addon:NewObject("Money")

local CharacterInfo = LibStub("CharacterInfo-1.0")

local COPPER_PER_SILVER = COPPER_PER_SILVER
local SILVER_PER_GOLD = SILVER_PER_GOLD

function Money:GetPlayerMoneyInfo()
    local charName, money = Money.storage:GetPlayerMoneyInfo()
    return CharacterInfo:RemoveRealm(charName), GetMoneyString(money, true)
end

function Money:IterableCharactersMoneyInfo()
    local charDisplayName
    local charName, money
    return function()
        charName, money = Money.storage:GetCharacterMoneyInfo(charName)
        while charName do
            charDisplayName = charName

            if CharacterInfo:IsCharacterOnConnectedRealm(charName) and Money.storage:IsConnectedRealmsNamesHidden() then
                charDisplayName = CharacterInfo:ShortConnectedRealm(charDisplayName)
            elseif CharacterInfo:IsCharacterOnCurrentRealm(charName) then
                charDisplayName = CharacterInfo:RemoveRealm(charDisplayName)
            end

            local fraction = math.floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD))

            if not CharacterInfo:IsSameCharacter(charName)
                and (fraction > Money.storage:GetMinMoneyAmount() or Money.storage:CanShowAllCharacters()) then
                return charDisplayName, GetMoneyString(money, true)
            end

            charName, money = Money.storage:GetCharacterMoneyInfo(charName)
        end
    end
end

function Money:GetTotalMoneyString()
    local totalMoney = 0
    local charName, money = Money.storage:GetCharacterMoneyInfo()
    while charName do
        if CharacterInfo:IsSameCharacter(charName)
            or CharacterInfo:IsCharacterOnCurrentRealm(charName)
            or CharacterInfo:IsCharacterOnConnectedRealm(charName) then
            totalMoney = totalMoney + money
        end
        charName, money = Money.storage:GetCharacterMoneyInfo(charName)
    end
    return GetMoneyString(totalMoney, true)
end
