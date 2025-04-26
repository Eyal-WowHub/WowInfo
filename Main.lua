local addon = LibStub("Addon-1.0"):New(...)

local Tooltip = LibStub("TooltipBuilder-1.0")

local Colorizer = addon.Colorizer

do
    local ADDON_LOAD_FAILED = ADDON_LOAD_FAILED:gsub("%%s:", "'%%s':")

    local function TryLoadAddOn(addonName)
        local loaded, reason = C_AddOns.LoadAddOn(addonName)
        if not loaded and reason then
            local state = RED_FONT_COLOR:WrapTextInColorCode(_G["ADDON_" .. reason])
            WowInfo:Warn(ADDON_LOAD_FAILED:format(addonName, state))
            return false
        end
        return true
    end

    function addon:OnInitialized()
        self.DB = LibStub("AceDB-3.0"):New("WowInfoDB", {}, true)

        SLASH_WOWINFO1 = "/wowinfo"
        SLASH_WOWINFO2 = "/wowi"
        SLASH_WOWINFO3 = "/wi"
        SlashCmdList["WOWINFO"] = function(input)
            if TryLoadAddOn("WowInfo_Options") then
                WowInfo:TriggerEvent("WOWINFO_OPTIONS_LOADED")
            end
        end
    end
end

do
    local MT = {
        __index = function(t, key)
            return Tooltip[key]
                    or Colorizer[key]
                    or rawget(t, "__friend") and t.__friend[key] 
                    or rawget(t, "__extension") and t.__extension[key]
        end
    }

    function addon:NewTooltip(name, extensionName)
        local tooltip = self:NewObject(name .. ".Tooltip")
        local friend = self:GetObject(name .. ".Extension", true)
        -- When the Tooltip and the Extension have the same name they are considered friends,
        -- meaning, the Tooltip can access the Extension as if it was part of the same object.
        tooltip.__friend = friend
        -- REVIEW: For now each Tooltip can have a single extension.
        if extensionName then
            tooltip.__extension = self:GetObject(extensionName .. ".Extension")
        end
        return setmetatable(tooltip, MT)
    end

    function addon:GetTooltip(name)
        return self:GetObject(name .. ".Tooltip")
    end
end

do
    local MT = {
        __index = function(t, key)
            return Tooltip[key]
                    or Colorizer[key]
                    or rawget(t, "__root") and t.__root[key]
        end
    }

    function addon:Extend(name)
        local root = self:GetObject(name)
        local extension = self:NewObject(name .. ".Extension")
        extension.__root = root
        return setmetatable(extension, MT)
    end
end