local _, addon = ...
local Professions = addon:NewObject("Professions")

local DATA = {
    OrderIndex = {}
}

local INFO = {}

local PROFESSION_RANKS =  {
    {75,  APPRENTICE},
    {150, JOURNEYMAN},
    {225, EXPERT},
    {300, ARTISAN},
    {375, MASTER},
    {450, GRAND_MASTER},
    {525, ILLUSTRIOUS},
    {600, ZEN_MASTER},
    {700, DRAENOR_MASTER},
    {800, LEGION_MASTER},
    {950, BATTLE_FOR_AZEROTH_MASTER}
}

function Professions:HasProfessions()
    for prof in self:IterableProfessionInfo() do
        if prof then
            return true
        end
    end
    return false
end

function Professions:IterableProfessionInfo()
    local prof1, prof2, arch, fish, cook = GetProfessions()
    DATA.OrderIndex[1] = prof1 or -1
    DATA.OrderIndex[2] = prof2 or -1
    DATA.OrderIndex[3] = cook or -1
    DATA.OrderIndex[4] = fish or -1
    DATA.OrderIndex[5] = arch or -1
    local i = 0
    local n = #DATA.OrderIndex
    return function()
        i = i + 1
        while i <= n do
            local index = DATA.OrderIndex[i]

            if index > -1 then
                local skillTitle
                local name, icon, skillLevel, skillMaxLevel, _, _, _, skillModifier, _, _, skillLineName = GetProfessionInfo(index)

                if skillLineName then
                    skillTitle = skillLineName
                else
                    for j=1, #PROFESSION_RANKS do
                        local value, title = PROFESSION_RANKS[j][1], PROFESSION_RANKS[j][2]
                        if skillMaxLevel < value then break end
                        skillTitle = title
                    end
                end

                INFO.name = name
                INFO.icon = icon
                INFO.skillTitle = skillTitle
                INFO.skillLevel = skillLevel
                INFO.skillMaxLevel = skillMaxLevel
                INFO.skillModifier = skillModifier

                return INFO
            end

            i = i + 1
        end
    end
end