local _, addon = ...
local Currency = addon:GetObject("Currency")
local CurrencyTracker = addon:NewObject("CurrencyTracker")

local CharacterInfo = LibStub("CharacterInfo-1.0")

local INFO = {}

local CACHE = {}

local function GetPlayerCurrencyQuantity(currencyID)
    if not currencyID then
        return 0
    end
    for entry in Currency:IterableCurrencyListEntryInfo() do
        if entry.ID and entry.ID == currencyID then
            return entry.quantity
        end
    end
    return 0
end

local function CacheCharactersCurrencyQuantity()
    local currentCharName = CharacterInfo:GetFullName()
    local charName, currency
    local charDisplayName
    for entry in Currency:IterableCurrencyListEntryInfo() do 
        if entry.ID then
            charName, currency = CurrencyTracker.storage:GetCharacterCurrencyInfo(charName)
            while charName do
                if charName ~= currentCharName then
                    local onCurrentRealm = CharacterInfo:IsCharacterOnCurrentRealm(charName)
                    local onConnectedRealm = CharacterInfo:IsCharacterOnConnectedRealm(charName)
                    if onCurrentRealm or onConnectedRealm then
                        for id, quantity in pairs(currency) do
                            if id == entry.ID then
                                charDisplayName = charName
                                if onConnectedRealm then
                                    charDisplayName = CharacterInfo:ShortConnectedRealm(charDisplayName)
                                else
                                    charDisplayName = CharacterInfo:RemoveRealm(charDisplayName)
                                end
                                local charEntry = CACHE[id]
                                if not charEntry then
                                    CACHE[id] = {}
                                    charEntry = CACHE[id]
                                end
                                charEntry[charDisplayName] = quantity
                            end
                        end
                    end
                end
                charName, currency = CurrencyTracker.storage:GetCharacterCurrencyInfo(charName)
            end
        end
    end
end

CurrencyTracker:RegisterEvent("PLAYER_LOGIN", function(self, eventName)
    CacheCharactersCurrencyQuantity()

    self:RegisterEvents(
        "PLAYER_LOGOUT",
        "CURRENCY_DISPLAY_UPDATE", 
        function(self, eventName)
            if eventName == "PLAYER_LOGOUT" then
                self.storage:StoreCurrencyData(Currency.IterableCurrencyListEntryInfo)
            elseif eventName == "CURRENCY_DISPLAY_UPDATE" then
                CacheCharactersCurrencyQuantity()
            end
        end)

    self.storage:RegisterEvent("WOWINFO_CURRENCY_TRACKER_RESET", function()
        for id in pairs(CACHE) do
            CACHE[id] = nil
        end
    end)
end)

function CurrencyTracker:IterableCharactersCurrencyInfo(index)
    local link = C_CurrencyInfo.GetCurrencyListLink(index)
    local currencyID = link and C_CurrencyInfo.GetCurrencyIDFromLink(link)
    local entry = CACHE[currencyID]
    local charName, quantity, visitedCurrentChar
    return function()
        if currencyID and not visitedCurrentChar then
            visitedCurrentChar = true
            return CharacterInfo:GetName(), GetPlayerCurrencyQuantity(currencyID), true
        end
        if entry then
            charName, quantity = next(entry, charName)
            if charName then
                return charName, quantity, false
            end
        end
        return nil, 0
    end
end

function CurrencyTracker:GetTotalQuantity(index)
    local totalQuantity = 0
    for _, quantity in self:IterableCharactersCurrencyInfo(index) do
        totalQuantity = totalQuantity + quantity
    end
    return totalQuantity
end