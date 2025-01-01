local _, addon = ...

WowInfo = addon:NewObject(addon:GetName())

function WowInfo:GetObject(name)
    return addon:GetObject(name)
end

function WowInfo:GetStorage(name)
    return addon:GetStorage(name)
end

function WowInfo:GetTooltip(name)
    return addon:GetTooltip(name)
end

do
    local WARNING_MSG = "<< %s >> %s"

    function WowInfo:Warn(...)
        local title = NORMAL_FONT_COLOR:WrapTextInColorCode(addon:GetName())
        print(YELLOW_FONT_COLOR:WrapTextInColorCode(WARNING_MSG:format(title, ...)))
    end
end