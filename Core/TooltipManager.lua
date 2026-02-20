local _, addon = ...
local Storage, DB = addon:NewStorage("TooltipManager")

--[[ Tooltip Target Contract
    Each tooltip must define a `target` table with one of two hook strategies:

    Frame Hook:
        target.button   (frame)    - Required (or `frame`). The UI frame to hook OnEnter/OnLeave on.
        target.frame     (frame)    - Required (or `button`). Alternative to `button`.
        target.onEnter   (function) - Required. Called when the mouse enters the frame.
        target.onLeave   (function) - Optional. Called when the mouse leaves the frame. Used for cleanup (e.g., canceling async loads).
        target.title     (string)   - Optional. If set, added as a header line before `onEnter` is called.

    Function Hook:
        target.funcName  (string)   - Required. The global function name (or method name if `table` is provided) to hook via hooksecurefunc.
        target.func      (function) - Required. Called after the hooked function executes.
        target.table     (table)    - Optional. If provided, hooks `table[funcName]` instead of `_G[funcName]`.

    Examples:

    -- Frame Hook (button):
    Tooltip.target = {
        button = CharacterMicroButton,
        onEnter = function()
            Tooltip:AddHeader("Currency:")
        end
    }

    -- Frame Hook (frame, with onLeave):
    Tooltip.target = {
        frame = MainStatusTrackingBarContainer.bars[4],
        onEnter = function()
            Tooltip:Clear()
            Tooltip:AddHeader("Experience:")
        end,
        onLeave = function()
            SomeModule:CancelPendingWork()
        end
    }

    -- Function Hook (global function):
    Tooltip.target = {
        funcName = "GameTime_UpdateTooltip",
        func = function()
            Tooltip:AddHeader("Daily Reset:")
        end
    }

    -- Function Hook (table method):
    Tooltip.target = {
        table = GameTooltip,
        funcName = "SetCurrencyToken",
        func = function(_, index)
            Tooltip:AddHeader("All Characters:")
        end
    }
]]

local defaults = {
    profile = {
        Enabled = {},
        Order = {
            ["CharacterMicroButton"] = {
                "Currency",
                "Durability",
                "GreatVaultProgress",
                "Reputation"
            },
            ["ProfessionMicroButton"] = {
                "Professions"
            },
            ["PlayerSpellsMicroButton"] = {
                "Talents"
            },
            ["AchievementMicroButton"] = {
                "Achievements"
            },
            ["QuestLogMicroButton"] = {
                "Quests"
            },
            ["GuildMicroButton"] = {
                "GuildFriends",
                "Communities"
            },
            ["LFDMicroButton"] = {
                "PvE",
                "MythicPlus",
                "Delves",
                "PvP"
            },
            ["CollectionsMicroButton"] = {
                "Collections"
            },
            ["EJMicroButton"] = {
                "MonthlyActivities"
            },
            ["MainMenuBarBackpackButton"] = {
                "Money"
            },
            ["QuickJoinToastButton"] = {
                "Friends"
            }
        }
    }
}

local function IsObjectTooltip(object)
    local name = object:GetName()
    return name and name:find(".Tooltip$") and object.target
end

local function RegisterTooltip(tooltip)
    local name = tooltip:GetName()

    if DB.profile.Enabled[name] == nil then
        DB.profile.Enabled[name] = true
    end

    local target = tooltip.target
    local frame = target.button or target.frame

    if frame then
        if target.onEnter then
            frame:HookScript("OnEnter", function(self)
                if not DB.profile.Enabled[name] then
                    return
                end

                -- NOTE: This prevents the tooltip from showing up when the button is disabled.
                if self.IsEnabled and not self:IsEnabled() then
                    return
                end

                if self == AchievementMicroButton and addon.MicroMenu:SetButtonTooltip(self, ACHIEVEMENT_BUTTON, "TOGGLEACHIEVEMENT") then
                    return
                end

                if target.title then
                    tooltip:AddHeader(target.title)
                end

                target.onEnter()
                tooltip:Show()
            end)
        end

        if target.onLeave then
            frame:HookScript("OnLeave", function(self)
                tooltip:Hide()
                target.onLeave()
            end)
        end
    elseif target.funcName then
        if target.table then
            hooksecurefunc(target.table, target.funcName, function(...)
                if not DB.profile.Enabled[name] then
                    return
                end

                target.func(...)
                tooltip:Show()
            end)
        else
            hooksecurefunc(target.funcName, function(...)
                if not DB.profile.Enabled[name] then
                    return
                end

                target.func(...)
                tooltip:Show()
            end)
        end
    end

    tooltip.isTooltipRegistered = true
end

local function IterableTooltips()
    local frameName, tooltips

    return function()
        frameName, tooltips = next(DB.profile.Order, frameName)
        return frameName, tooltips
    end
end

local function RegisterTooltips()
    for _, tooltips in IterableTooltips() do
        for _, name in ipairs(tooltips) do
            local tooltip = addon:GetTooltip(name)

            RegisterTooltip(tooltip)
        end
    end

    -- NOTE: Register tooltips that are fixed to a frame and don't appear in the `Order` table.
    for object in addon:IterableObjects() do
        if IsObjectTooltip(object) and not object.isTooltipRegistered then
            RegisterTooltip(object)
        end
    end
end

function Storage:OnInitialized()
    DB = self:RegisterDB(defaults)

    RegisterTooltips()
end

function Storage:IterableEnabledTooltips()
    local i = 0
    local sortedKeys = {}

    for key in pairs(DB.profile.Enabled) do
        table.insert(sortedKeys, key)
    end

    table.sort(sortedKeys)

    return function()
        i = i + 1
        return sortedKeys[i]
    end
end

function Storage:ToggleTooltip(name)
    if DB.profile.Enabled[name] then
        DB.profile.Enabled[name] = false
    else
        DB.profile.Enabled[name] = true
    end
end

function Storage:IsEnabled(name)
    return DB.profile.Enabled[name]
end

