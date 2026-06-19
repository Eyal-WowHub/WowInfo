local _, addon = ...
local Speedometer = addon:NewObject("Speedometer")

local issecretvalue = issecretvalue

-- Combat gate: while locked down the movement speed is a secret number, so the
-- readout is cleared on combat enter and resumes on combat leave. The IsSecret
-- fallback below still guards any secret value seen outside of combat.
local inCombat = false

--- Returns true when the value is a secret value (WoW 12.0.0+ restricted
--- content). Safe on older clients where issecretvalue is unavailable.
--- @param value any
--- @return boolean
local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

local function GetSpeedPercent(speed)
    if speed == 0 then
        return 0
    else
        return Round(speed / BASE_MOVEMENT_SPEED * 100)
    end
end

local function GetCurrentSpeedInfo()
    local currentSpeed = GetUnitSpeed("player")
    local isGliding, _, forwardSpeed = C_PlayerInfo.GetGlidingInfo()

    if isGliding then
        currentSpeed = forwardSpeed
    end

    -- In restricted content the movement speed is a secret number that cannot
    -- be compared or divided, so the standing check and percentage maths are
    -- skipped and an unknown speed is reported instead of erroring.
    local secret = IsSecret(currentSpeed)

    local status
    if isGliding then
        status = "Glide"
    elseif not secret and currentSpeed == 0 then
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

    if secret then
        return status, nil
    end

    return status, GetSpeedPercent(currentSpeed)
end

function Speedometer:OnInitialized()
    -- Handle /reload or login while already in combat: the enter event won't
    -- replay, so seed the flag from the current lockdown state.
    inCombat = InCombatLockdown()

    self:RegisterEvent("PLAYER_REGEN_DISABLED", function()
        inCombat = true
        Speedometer:TriggerEvent("WOWINFO_PLAYER_STOPPED_MOVING")
    end)

    self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        inCombat = false
    end)

    C_Timer.NewTicker(0.5, function()
        if inCombat then return end

        local status, currentSpeed = GetCurrentSpeedInfo()
        if status == "Stand" then
            Speedometer:TriggerEvent("WOWINFO_PLAYER_STOPPED_MOVING")
        else
            if currentSpeed then
                currentSpeed = format("%d%%", currentSpeed)
            else
                currentSpeed = addon.L["N/A"]
            end
            Speedometer:TriggerEvent("WOWINFO_PLAYER_STARTED_MOVING", status, currentSpeed)
        end
    end)
end


