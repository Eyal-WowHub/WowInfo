local _, addon = ...
local MicroMenu = {}
addon.MicroMenu = MicroMenu

-- NOTE: The `AchievementMicroButton` tooltip sometimes doesn't show up because `tooltipText` is nil.
--       This might be a Blizzard bug. This function aims to fix that issue by setting the tooltip text if it's missing.
--       This is essential for `WowInfo` because without the tooltip text, the tooltip won't show up.
function MicroMenu:SetButtonTooltip(button, text, action)
    if button:IsEnabled() then
        if not button.tooltipText then
            button.tooltipText = MicroButtonTooltipText(text, action)
            local script = button:GetScript("OnEnter")
            if script then
                script(button)
            end
            return true
        end
    end
    return false
end