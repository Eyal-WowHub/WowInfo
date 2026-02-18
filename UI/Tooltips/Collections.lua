local _, addon = ...
local Collections = addon:GetObject("Collections")
local Achievements = addon:GetObject("Achievements")
local Tooltip = addon:NewTooltip("Collections")

local L = addon.L

local ACHIEVEMENT_LINE_FORMAT = "- %s: |cffffffff%d|r / |cff20ff20%d|r"

function Tooltip:AddAchievementLine(callback)
    local name, currAmount, reqAmount = callback()
    if name then
        self:AddFormattedLine(ACHIEVEMENT_LINE_FORMAT, name, currAmount, reqAmount)
    end
    return self
end

Tooltip.target = {
    button = CollectionsMicroButton,
    onEnter = function()
        local totalMounts = Collections:GetTotalMounts()
        if totalMounts  then
            Tooltip
                :AddFormattedHeader(L["Mounts: X"], totalMounts)
                :AddAchievementLine(Achievements.GetMountAchievementInfo)
        end
    
        local totalPets = Collections:GetTotalPets()
        if totalPets then
            Tooltip
                :AddFormattedHeader(L["Pets: X"], totalPets)
                :AddAchievementLine(Achievements.GetPetsAchievementInfo)

            local hasDead = Collections:HasDeadPets()
            if hasDead then
                Tooltip:AddLine(L["Dead Pets!"])
            end

            local pets = Collections:GetLoadedPetsInfo()
            if pets then
                for _, pet in ipairs(pets) do
                    local healthText = L["X / Y HP"]:format(pet.health, pet.maxHealth)
                    Tooltip:SetDoubleLine(pet.name, healthText)
                    if pet.health == 0 then
                        Tooltip:SetRedColor()
                    elseif pet.health == pet.maxHealth then
                        Tooltip:SetGreenColor()
                    end
                    Tooltip:ToLine()
                end
            end
        end
    
        local totalLearnedToys, totalToys = Collections:GetTotalToys()
        if totalLearnedToys then
            Tooltip
                :AddFormattedHeader(L["Toys: X / Y"], totalLearnedToys, totalToys)
                :AddAchievementLine(Achievements.GetToysAchievementInfo)
        end
    end
}