---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by seancheey.
--- DateTime: 10/20/20 9:08 PM
---
local assertNotNull = require("__MiscLib__/assert_not_null")
--- @type Vector2D
local Vector2D = require("__MiscLib__/vector2d")

--- Represents the dictionary of minimum travel distance from endingEntity to some belt (represented by a position vector + direction)
--- @class MinDistanceDict
--- @type MinDistanceDict
local MinDistanceDict = {}
MinDistanceDict.__directionNum = 8
MinDistanceDict.__index = MinDistanceDict

--- @return MinDistanceDict
function MinDistanceDict:new()
    return setmetatable({}, self)
end

function MinDistanceDict.__marshalize(vector, direction)
    return tostring(vector.x) .. '|' .. tostring(vector.y) .. '|' .. tostring(direction)
end

function MinDistanceDict.__unmarshalize(key)
    local sep1 = string.find(key, '|')
    local x = string.sub(key, 1, sep1 - 1)
    local sep2 = string.find(key, '|', sep1 + 1)
    local y = string.sub(key, sep1 + 1, sep2 - 1)
    local direction = string.sub(key, sep2 + 1, -1)
    return Vector2D.new(tonumber(x), tonumber(y)), tonumber(direction)
end

--- @param vector Vector2D
function MinDistanceDict:put(vector, direction, val)
    assertNotNull(self, vector, direction, val)
    local key = MinDistanceDict.__marshalize(vector, direction)
    self[key] = val
end

--- @return number
function MinDistanceDict:get(vector, direction)
    assertNotNull(self, vector, direction)

    return self[MinDistanceDict.__marshalize(vector, direction)]
end

--- @param f fun(key1:vector, key2: defines.direction, val:number)
function MinDistanceDict:forEach(f)
    for key, val in pairs(self) do
        local vector, direction = MinDistanceDict.__unmarshalize(key)
        f(vector, direction, val)
    end
end

return MinDistanceDict