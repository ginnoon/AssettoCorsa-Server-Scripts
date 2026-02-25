local wrongState = false

local function getTrackDirection(car)
    local t = ac.worldCoordinateToTrack(car.position)
    if not t then return nil end

    local p1 = ac.trackToWorldCoordinate(t + 0.002)
    local p2 = ac.trackToWorldCoordinate(t - 0.002)

    if not p1 or not p2 then return nil end

    return (p1 - p2):normalize()
end

local function isWrongWay(car)
    if car.speedKmh < 5 then return false end

    local trackDir = getTrackDirection(car)
    if not trackDir then return false end

    return car.look:dot(trackDir) < -0.3
end

function script.update(dt)
    local car = ac.getCar(0)

    if not car then return end

    local wrong = isWrongWay(car)

    if wrongState ~= wrong then
        wrongState = wrong
        physics.setCarCollisions(0, not wrong)
    end
end
