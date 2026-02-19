local _, addon = ...
local Collections = addon:GetObject("Collections")
local Achievements = addon:GetObject("Achievements")
local Tooltip = addon:NewTooltip("Collections")

local L = addon.L

local ACHIEVEMENT_LINE_FORMAT = "- %s: |cffffffff%d|r / |cff20ff20%d|r"
local PET_LINE_FORMAT = "|T%s:0|t %s"

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
                Tooltip:AddEmptyLine()
                for _, pet in ipairs(pets) do
                    Tooltip
                        :SetFormattedLine(PET_LINE_FORMAT, pet.icon, pet.name)
                        :Indent()
                    if pet.healthPct == 0 then
                        Tooltip:SetLine(DEAD):SetRedColor()
                    elseif pet.healthPct == 1 then
                        Tooltip:SetLine(FormatPercentage(pet.healthPct)):SetGreenColor()
                    else
                        Tooltip:SetLine(FormatPercentage(pet.healthPct))
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