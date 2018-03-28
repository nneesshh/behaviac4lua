--- Behaviac lib Component: stochastic composite node.
-- @module CompositeStochastic.lua
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
local Composite = require(ppdir .. "core.Composite")
local CompositeStochastic = class("CompositeStochastic", Composite)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("CompositeStochastic", CompositeStochastic)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("CompositeStochastic", "Composite")
local _M = CompositeStochastic

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_method   = false
end

function _M:release()
    _M.super.release(self)

    self.m_method   = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]
        
        if nameStr == "RandomGenerator" then
            self.m_method = NodeParser.parseMethod(valueStr)
        end
    end
end

function _M:isCompositeStochastic()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)

    clearIndexSet(tick)
end

function _M:onEnter(agent, tick)
    _G.BEHAVIAC_ASSERT(#self.m_children > 0, "[_M:onEnter()] #self.m_children > 0")

    self:randomChild(agent, tick)
    self:setActiveChildIndex(tick, 1)
    return true
end

function _M:onExit(agent, status)
end

function _M:update(agent, tick, childStatus)
    local bFirst = true
    local activeChildIndex = self:getActiveChildIndex(tick)
    _G.BEHAVIAC_ASSERT(activeChildIndex ~= constInvalidChildIndex, "[_M:update()] activeChildIndex ~= constInvalidChildIndex")

    while true do
        local s = childStatus

        if not bFirst or s == EBTStatus.BT_RUNNING then
            local indexSet = self:getIndexSet(tick)
            local childIndex = indexSet[activeChildIndex]
            local pChild = self.m_children[childIndex]
            s = tick:exec(pChild, agent)
        end

        bFirst = false

        -- If the child succeeds, or keeps running, do the same.
        if s ~= EBTStatus.BT_FAILURE then
            return s
        end

        -- Hit the end of the array, job done!
        activeChildIndex = activeChildIndex + 1
        self:setActiveChildIndex(tick, activeChildIndex)

        if activeChildIndex > #self.m_children then
            return EBTStatus.BT_FAILURE
        end
    end
end

function _M:randomChild(agent, tick)
    _G.BEHAVIAC_ASSERT(self:isCompositeStochastic(), "[_M:randomChild()] self:isCompositeStochastic")

    local n = #self.m_children
    for i = 1, n do
        self:setIndexSet(i, i)
    end

    for i = 1, n do
        local method = false
        if pNode then
            method = pNode.m_method
        end
        
        local index1 = math.ceil(n * common.getRandomValue(method, agent))
        _G.BEHAVIAC_ASSERT(index1 <= n)

        local index2 = math.ceil(n * common.getRandomValue(method, agent))
        _G.BEHAVIAC_ASSERT(index2 <= n)

        -- swap
        if index1 ~= index2 then
            local indexSet = self:getIndexSet(tick)
            local old = indexSet[index1]
            indexSet[index1] = indexSet[index2]
            indexSet[index2] = old
        end
    end
end

function _M:clearIndexSet(tick)
    tick:setNodeMem("indexSet", {}, self)
end

function _M:setIndexSet(tick, key, value)
    local indexSet = self:getIndexSet(tick)
    indexSet[key] = value
end

function _M:getIndexSet(tick)
    local indexSet = tick:getNodeMem("indexSet", self)
    if nil == indexSet then
        indexSet = {}
        tick:setNodeMem("indexSet", indexSet, self)
    end
    return indexSet
end

return _M