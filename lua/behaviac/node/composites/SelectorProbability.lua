--- Behaviac lib Component: selector probability composite node.
-- @module SelectorProbability.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

-- Localize
local ppdir = (...):gsub('%.[^%.]+%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."
local enums = require(ppdir .. "enums")
local common = require(ppdir .. "common")

local EBTStatus                 = enums.EBTStatus
local ENodePhase                = enums.ENodePhase
local EPreconditionPhase        = enums.EPreconditionPhase
local TriggerMode               = enums.TriggerMode
local EOperatorType             = enums.EOperatorType

local constSupportedVersion     = enums.constSupportedVersion
local constInvalidChildIndex    = enums.constInvalidChildIndex
local constBaseKeyStrDef        = enums.constBaseKeyStrDef
local constPropertyValueType    = enums.constPropertyValueType

local Logging                   = common.d_log
local StringUtils               = common.StringUtils

-- Class
-- Choose a child to execute based on the probability have set. then return the child execute result.
-- For example, if there were two children with a weight of one, each would have a 50% chance of being executed.
-- If another child with a weight of eight were added, the previous children would have a 10% chance of being
-- executed, and the new child would have an 80% chance of being executed.
-- This weight system is intended to facilitate the fine-tuning of behaviors.
local Composite = require(ppdir .. "core.Composite")
local SelectorProbability = class("SelectorProbability", Composite)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("SelectorProbability", SelectorProbability)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("SelectorProbability", "Composite")
local _M = SelectorProbability

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_randomGenerator = false
end

function _M:release()
    _M.super.release()
    
    self.m_randomGenerator = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "RandomGenerator" then
            if valueStr[0] ~= "" then
                self.m_randomGenerator = NodeParser.parseMethod(valueStr)
            end
        else
            -- _G.BEHAVIAC_ASSERT(0, "unrecognized property")
        end
    end
end

function _M:addChild(pBehavior)
    _G.BEHAVIAC_ASSERT(pBehavior:isDecoratorWeight(), "[_M:addChild()] pBehavior:isDecoratorWeight")

    _M.super.addChild(self, pBehavior)
end

function _M:isSelectorProbability()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)

    self:setTotalSum(tick, 0.0)
    self:clearWeightMap(tick)
end

function _M:onEnter(agent, tick)
    _G.BEHAVIAC_ASSERT(#self.m_children > 0, "[_M:onEnter()] #self.m_children > 0")
    self:setActiveChildIndex(tick, constInvalidChildIndex)

    local totalSum = 0.0
    self:clearWeightMap(tick)

    for _, pChild in ipairs(self.m_children) do
        _G.BEHAVIAC_ASSERT(pChild:isDecoratorWeight(), "[_M:onEnter()] pChild:isDecoratorWeight")
        local weight = pChild:getWeight(agent)
        self:addWeightingMapWeight(tick, weight)

        totalSum = totalSum + weight
    end
    self:setTotalSum(tick, totalSum)

    local weightingMap = self:getWeightingMap(tick)
    _G.BEHAVIAC_ASSERT(#weightingMap == #self.m_children, "[_M:onEnter()] #weightingMap == self.m_children")
    return true
end

function _M:onExit(agent, tick, status)
    self:setActiveChildIndex(tick, constInvalidChildIndex)
end

function _M:update(agent, tick, childStatus)    
    _G.BEHAVIAC_ASSERT(self:isSelectorProbability(), "[_M:update()] self:isSelectorProbability")
    if childStatus ~= EBTStatus.BT_RUNNING then
        return childStatus
    end

    -- check if we've already chosen a node to run
    local activeChildIndex = self:getActiveChildIndex(tick)
    if activeChildIndex ~= constInvalidChildIndex then
        local pChild = self.m_children[activeChildIndex]
        return tick:exec(pChild, agent)
    end

    local weightingMap = self:getWeightingMap(tick)
    _G.BEHAVIAC_ASSERT(#weightingMap == #self.m_children, "[_M:update()] #weightingMap == #self.m_children")

    -- generate a number between 0 and the sum of the weights
    local chosen = self.m_totalSum * common.getRandomValue(self.m_randomGenerator, agent)
    local sum = 0

    for i = 1, #self.m_children do
        local w = weightingMap[i]
        sum = sum + w

        if w > 0 and sum >= chosen then
            local pChild = self.m_children[i]
            local status = tick:exec(pChild, agent)
            if status == EBTStatus.BT_RUNNING then
                activeChildIndex = i
            else
                activeChildIndex = constInvalidChildIndex
            end
            self:setActiveChildIndex(tick, activeChildIndex)
            -- print("[_M:update()] 1", activeChildIndex, pChild.__name)
            return status
        end
    end
    -- print("[_M:update()]", activeChildIndex)
    return EBTStatus.BT_FAILURE
end

function _M:setTotalSum(tick, n)
    tick:setNodeMem("totalSum", n, self)
end

function _M:getTotalSum(tick)
    return tick:getNodeMem("totalSum", self)
end

function _M:clearWeightingMap(tick)
    tick:setNodeMem("weightingMap", {}, self)
end

function _M:addWeightingMapWeight(tick, weight)
    local weightingMap = self:getWeightingMap(tick)
    table.insert(weightingMap, weight)
end

function _M:getWeightingMap(tick)
    local indexSet = tick:getNodeMem("weightingMap", self)
    if nil == indexSet then
        indexSet = {}
        tick:setNodeMem("weightingMap", indexSet, self)
    end
    return indexSet
end

return _M