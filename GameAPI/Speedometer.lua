local _, addon = ...
local Speedometer = addon:NewObject("Speedometer")

local function GetSpeedPercent(speed)
    if speed == 0 then
        return 0
    else
        return Round(speed / BASE_MOVEMENT_SPEED * 100)
    end
end

local function GetCurrentSpeedInfo()
    local status
    local currentSpeed = GetUnitSpeed("player")
    local isGliding, _, forwardSpeed = C_PlayerInfo.GetGlidingInfo()

    if isGliding then
        status = "Glide"
        currentSpeed = forwardSpeed
    elseif currentSpeed == 0 then
        status = "Stand"
    elseif IsFlying() then
        status = "Fly"
    elseif IsSwimming() then
        status = "Swim"
    elseif UnitOnTaxi("player") then
        status = "Taxi"
    elseif IsMounted() then
        status = "Ride"
    else
        status = "Move"
    end

    return status, GetSpeedPercent(currentSpeed)
end

function Speedometer:OnInitialized()
    C_Timer.NewTicker(0.5, function()
        local status, currentSpeed = GetCurrentSpeedInfo()
        if status == "Stand" then
            Speedometer:TriggerEvent("WOWINFO_PLAYER_STOPPED_MOVING")
        else
            currentSpeed = format("%d%%", currentSpeed)
            Speedometer:TriggerEvent("WOWINFO_PLAYER_STARTED_MOVING", status, currentSpeed)
        end
    end)
end


