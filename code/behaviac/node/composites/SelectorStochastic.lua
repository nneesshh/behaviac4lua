--- Behaviac lib Component: selector stochastic composite node.
-- @module SelectorStochastic.lua
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
-- The Selector runs the children from the first sequentially until the child which returns success.
-- for SelectorStochastic, the children are not sequentially selected, instead it is selected stochasticly.
-- for example: the children might be [0, 1, 2, 3, 4]
-- Selector always select the child by the order of 0, 1, 2, 3, 4
-- while SelectorStochastic, sometime, it is [4, 2, 0, 1, 3], sometime, it is [2, 3, 0, 4, 1], etc.
local CompositeStochastic = require(cwd .. "CompositeStochastic")
local SelectorStochastic = class("SelectorStochastic", CompositeStochastic)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("SelectorStochastic", SelectorStochastic)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("SelectorStochastic", "CompositeStochastic")
local _M = SelectorStochastic

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)
end

function _M:release()
    _M.super.release(self)
end

function _M:checkIfInterrupted(agent, tick)
    return self:evaluteCustomCondition(agent, tick)
end

function _M:isSelectorStochastic()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:update(agent, tick, childStatus)
    local bFirst = true
    local activeChildIndex = self:getActiveChildIndex(tick)
    _G.BEHAVIAC_ASSERT(activeChildIndex ~= constInvalidChildIndex, "[_M:update()] activeChildIndex ~= constInvalidChildIndex")

    -- Keep going until a child behavior says its running.
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

return _M