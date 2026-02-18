local _, addon = ...
local MythicPlus = addon:GetObject("MythicPlus")
local Tooltip = addon:NewTooltip("MythicPlus")

local L = addon.L

local KEYSTONE_FORMAT = "%s |cffffffff+%d|r"
local DUNGEON_LEVEL_FORMAT = "+%d"

Tooltip.target = {
    button = LFDMicroButton,
    onEnter = function()
        if not C_MythicPlus.IsMythicPlusActive() then return end

        local score, scoreColor = MythicPlus:GetOverallScore()

        if score then
            scoreColor = scoreColor or HIGHLIGHT_FONT_COLOR

            Tooltip
                :SetFormattedLine(L["Mythic+: X"], score)
                :SetColor(scoreColor)
                :ToHeader()
        else
            Tooltip:AddHeader(L["Mythic+:"])
        end

        local keystone = MythicPlus:GetKeystoneInfo()

        if keystone then
            Tooltip
                :SetFormattedLine(KEYSTONE_FORMAT, keystone.name, keystone.level)
                :ToLine()
        end

        local weeklyCount = MythicPlus:GetWeeklyRunCount()

        if weeklyCount > 0 then
            Tooltip:AddFormattedLine(L["This Week: X Runs"], weeklyCount)
        end

        if IsShiftKeyDown() then
            for dungeon in MythicPlus:IterableSeasonBestInfo() do
                if dungeon.level > 0 then
                    local levelText = DUNGEON_LEVEL_FORMAT:format(dungeon.level)
                    local color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(dungeon.score)
                    Tooltip:SetDoubleLine(dungeon.name, levelText)
                    if color then
                        Tooltip:SetColor(color)
                    else
                        Tooltip:SetHighlight()
                    end
                    Tooltip:ToLine()
                else
                    Tooltip
                        :SetLine(dungeon.name)
                        :SetGrayColor()
                        :ToLine()
                end
            end
        end
    end
}
