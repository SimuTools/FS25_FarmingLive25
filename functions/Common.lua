function FarmingLive:pickDifferent(values, previous)
    if type(values) ~= "table" or #values == 0 then
        return previous
    end

    if #values == 1 then
        return values[1]
    end

    local candidate = previous
    local tries = 0
    while candidate == previous and tries < 10 do
        candidate = values[math.random(1, #values)]
        tries = tries + 1
    end

    return candidate
end

function FarmingLive:pad2(value)
    return string.format("%02d", tonumber(value) or 0)
end

function FarmingLive:formatClock(totalSeconds)
    local seconds = math.max(0, math.floor(tonumber(totalSeconds) or 0))
    local minutes = math.floor(seconds / 60)
    local remainder = seconds % 60
    return self:pad2(minutes), self:pad2(remainder), minutes, remainder
end
