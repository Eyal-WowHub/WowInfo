local _, addon = ...
local Currency = addon:NewObject("Currency")

local INFO = {}

local DATA = {
    expansions = {},
    expansionHeader = "",
    currentExpansionLevel = 0,
    CollapsedIndexes = {}
}

local CACHE = {
    size = 0
}

local _G = _G
local PLAYER_V_PLAYER = PLAYER_V_PLAYER

local function GetCurrencyListSize()
    return CACHE.size
end

local function GetCurrencyListEntryInfo(index)
    local entry = CACHE[index]
    if entry then
        INFO.ID = entry.ID
        INFO.name = entry.name
        INFO.headerName = entry.headerName
        INFO.isHeader = entry.isHeader
        INFO.isTradeable = entry.isTradeable
        INFO.quantity = entry.quantity
        INFO.maxQuantity = entry.maxQuantity
        INFO.iconFileID = entry.iconFileID
        INFO.isAccountWide = entry.isAccountWide
        return INFO
    end
end

local function IterableCurrencyListEntryInfo()
    local i = 0
    local n = GetCurrencyListSize()
    return function()
        i = i + 1
        while i <= n do
            local entry = GetCurrencyListEntryInfo(i)
            if entry and not entry.isAccountWide then
                return entry
            end
            i = i + 1
        end
    end
end

local function IterableHeaderInfo(headerName)
    local i = 0
    local n = GetCurrencyListSize()
    return function()
        i = i + 1
        while i <= n do
            local entry = GetCurrencyListEntryInfo(i)
            if entry and headerName:find(entry.headerName)  then
                return entry
            end
            i = i + 1
        end
    end
end

local function FindHeaderByName(headerName)
    for entry in IterableCurrencyListEntryInfo() do
        if entry.quantity > 0 and headerName:find(entry.headerName) then
            return true
        end
    end
    return false
end

local function CacheCurrencyInfo()
    local i = 1
    local currency = C_CurrencyInfo.GetCurrencyListInfo(i)
    local headerName, currencyID

    while currency do
        currencyID = nil

        if not currency.isHeaderExpanded then
            C_CurrencyInfo.ExpandCurrencyList(i, true)
            table.insert(DATA.CollapsedIndexes, i)
        end

        local entry = CACHE[i]

        if not entry then
            CACHE[i] = {}
            entry = CACHE[i]
        end

        if not currency.isHeader then
            local link = C_CurrencyInfo.GetCurrencyListLink(i)
            if link then
                currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(link)
            end
        else
            headerName = currency.name
        end

        entry.ID = currencyID
        entry.name = currency.name
        entry.headerName = headerName
        entry.isHeader = currency.isHeader
        entry.isTradeable = currency.isTradeable
        entry.quantity = currency.quantity
        entry.maxQuantity = currency.maxQuantity
        entry.iconFileID = currency.iconFileID
        entry.isAccountWide = currency.isAccountWide
        
        CACHE.size = i

        i = i + 1
        currency = C_CurrencyInfo.GetCurrencyListInfo(i)
    end

    for i = #DATA.CollapsedIndexes, 1, -1 do
        local collapsedIndex = DATA.CollapsedIndexes[i]
        C_CurrencyInfo.ExpandCurrencyList(collapsedIndex, false)
        DATA.CollapsedIndexes[i] = nil
    end
end

local function SetLatestExpansionHeader()
    local headerName
    local expansionLevel = DATA.currentExpansionLevel + 1
    while expansionLevel > 0 do
        headerName = DATA.expansions[expansionLevel]
        if not FindHeaderByName(headerName) then
            -- If we didn't find a header for the latest expansion available
            -- then try the expansion before that
            expansionLevel = expansionLevel - 1
        else
            break
        end
    end
    DATA.expansionHeader = headerName
end

function Currency:OnInitializing()
    DATA.currentExpansionLevel = GetClampedCurrentExpansionLevel()
    for i = 0, DATA.currentExpansionLevel do
        table.insert(DATA.expansions, _G["EXPANSION_NAME" .. i])
    end
end

Currency:RegisterEvent("PLAYER_LOGIN", function(self, eventName)
    CacheCurrencyInfo()
    SetLatestExpansionHeader()

    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE", 
        function(self, eventName)
            CacheCurrencyInfo()
            SetLatestExpansionHeader()
        end)
end)

Currency.GetCurrencyListSize = GetCurrencyListSize
Currency.GetCurrencyListEntryInfo = GetCurrencyListEntryInfo
Currency.IterableCurrencyListEntryInfo = IterableCurrencyListEntryInfo

function Currency:IterableLatestExpansionInfo()
    return IterableHeaderInfo(DATA.expansionHeader)
end

function Currency:IterablePvPInfo()
    return IterableHeaderInfo(PLAYER_V_PLAYER)
end