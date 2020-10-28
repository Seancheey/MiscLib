---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by seancheey.
--- DateTime: 10/20/20 9:04 PM
---
local assertNotNull = require("assert_not_null")

--- Transport chain is an intermediate generated backward linked list node that represents a whole transport line.
--- Each node in this linked list represents either one belt, or a pair of underground belt. (in this case the "entity" field represents the input belt, and output belt is inferred by entityDistance + direction)
--- @class PathNode
--- @field pathUnit PathSegment
--- @field prevChain PathNode
--- @field cumulativeDistance number
--- @field leftCumulativeTurns number can't be negative, if ever >=3, we enforce collision check
--- @field rightCumulativeTurns number can't be negative, if ever >=3, we enforce collision check
--- @field enforceCollisionCheck boolean if true, we must check if the transport chain collide with any of previous chain
local PathNode = {}
PathNode.__index = PathNode

--- @param pathUnit PathSegment
--- @param prevChain PathNode
--- @param playerConfig LineConnectConfig
--- @return PathNode
function PathNode:new(pathUnit, prevChain, playerConfig)
    assertNotNull(pathUnit)
    playerConfig = playerConfig or {}
    local distanceIncrease = pathUnit.distance
    -- if prefer on ground, punish underground belts
    if distanceIncrease > 1 then
        if playerConfig.preferOnGround then
            distanceIncrease = distanceIncrease + (playerConfig.preferGroundModeUndergroundPunishment or 1)
        end
        distanceIncrease = distanceIncrease * 0.999
    end
    -- punish a little to to turning, set as 2 since this punishment is greater than the reward for going with underground belt.
    if prevChain and pathUnit.direction ~= prevChain.pathUnit.direction then
        distanceIncrease = distanceIncrease + (playerConfig.turningPunishment or 2)
    end
    if prevChain then
        local directionDifference = (pathUnit.direction - prevChain.pathUnit.direction + 4) % 8 - 4
        local leftTurnNum = prevChain.leftCumulativeTurns
        local rightTurnNum = prevChain.rightCumulativeTurns
        local enforceCollisionCheck = prevChain.enforceCollisionCheck
        if not enforceCollisionCheck then
            if directionDifference == 2 then
                -- right turn
                rightTurnNum = rightTurnNum + 1
                leftTurnNum = leftTurnNum == 0 and leftTurnNum or leftTurnNum - 1
            elseif directionDifference == -2 then
                -- left turn
                leftTurnNum = leftTurnNum + 1
                rightTurnNum = rightTurnNum == 0 and rightTurnNum or rightTurnNum - 1
            end
            -- if turn num >= 3, it means there is a possibility for the transport line to form a circle and thus have a chance of self-colliding
            if rightTurnNum >= 3 or leftTurnNum >= 3 then
                enforceCollisionCheck = true
            end
        end
        return setmetatable({
            pathUnit = pathUnit,
            prevChain = prevChain,
            cumulativeDistance = (prevChain.cumulativeDistance + distanceIncrease) or 0,
            enforceCollisionCheck = enforceCollisionCheck,
            leftCumulativeTurns = leftTurnNum,
            rightCumulativeTurns = rightTurnNum
        }, self)
    else
        return setmetatable({
            pathUnit = pathUnit,
            prevChain = prevChain,
            cumulativeDistance = 0,
            leftCumulativeTurns = 0,
            rightCumulativeTurns = 0,
            enforceCollisionCheck = false
        }, PathNode)
    end
end

--- @param placeFunc fun(entity: LuaEntityPrototype)
function PathNode:placeAllEntities(placeFunc)
    local transportChain = self
    local place = function(entity)
        if transportChain.prevChain ~= nil then
            placeFunc(entity)
        end
    end
    while transportChain ~= nil do
        for _, entitySpec in ipairs(transportChain.pathUnit:toEntitySpecs()) do
            place(entitySpec)
        end
        transportChain = transportChain.prevChain
    end
end

return PathNode