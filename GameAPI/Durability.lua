local _, addon = ...
local Durability = addon:NewObject("Durability")

local CACHE = {
    inventoryPct = 0, 
    bagsPct = 0
}

local NUM_BAG_FRAMES = 4

local SLOTS = {
    "HeadSlot",
    "ShoulderSlot",
    "ChestSlot",
    "WristSlot",
    "HandsSlot",
    "WaistSlot",
    "LegsSlot",
    "FeetSlot",
    "MainHandSlot",
    "SecondaryHandSlot"
}

local function GetPercentage(current, total)
    if current and total > 0 then
        local perc = current / total
        local fixed = perc
        -- Makes sure we never round down to 0 so we can distinguish between completely broken and fully functional
        if perc > 0 then
            fixed = math.max(0.01, perc)
        end
        return fixed, perc
    end
end

local function CacheDurabilityInfo()
    local inventory, inventoryMax = 0, 0
    local bags, bagsMax = 0, 0

    for _, slot in ipairs(SLOTS) do
        local durability, durabilityMax = GetInventoryItemDurability(GetInventorySlotInfo(slot))
        if durability and durabilityMax then
            local _, exactPct = GetPercentage(durability, durabilityMax)
            -- Adds item durability values to total inventory durability value
            inventory = inventory + exactPct
            inventoryMax = inventoryMax + 1
        end
    end

    -- Scans bags items durability status
    for bag = 0, NUM_BAG_FRAMES do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local durability, durabilityMax = C_Container.GetContainerItemDurability(bag, slot)
            if durability then
                bags = bags + durability
                bagsMax = bagsMax + durabilityMax
            end
        end
    end

    CACHE.inventoryPct = GetPercentage(inventory, inventoryMax)
    CACHE.bagsPct = GetPercentage(bags, bagsMax)
end

Durability:RegisterEvents(
    "UPDATE_INVENTORY_DURABILITY",
    "PLAYER_EQUIPMENT_CHANGED",
    function(_, eventName)
        CacheDurabilityInfo()
    end)

function Durability:GetPercentages()
    return CACHE.inventoryPct, CACHE.bagsPct
end