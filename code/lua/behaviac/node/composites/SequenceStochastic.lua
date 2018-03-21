--- Behaviac lib Component: sequence stochastic composite node.
-- @module SequenceStochastic.lua
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
-- SequenceStochastic tick each of their children in a random order. If a child returns Failure,
-- so does the Sequence. If it returns Success, the Sequence will move on to the next child in line
-- and return Running.If a child returns Running, so does the Sequence and that same child will be
-- ticked again next time the Sequence is ticked.Once the Sequence reaches the end of its child list,
-- it returns Success and resets its child index – meaning the first child in the line will be ticked
-- on the next tick of the Sequence.
local CompositeStochastic = require(cwd .. "CompositeStochastic")
local SequenceStochastic = class("SequenceStochastic", CompositeStochastic)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("SequenceStochastic", SequenceStochastic)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("SequenceStochastic", "CompositeStochastic")
local _M = SequenceStochastic

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

function _M:isSequenceStochastic()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:update(agent, tick, childStatus)
    local activeChildIndex = self:getActiveChildIndex(tick)
    _G.BEHAVIAC_ASSERT(activeChildIndex <= #self.m_children, "[_M:update()] activeChildIndex <= #self.m_children")
    
    local bFirst = true
    --  Keep going until a child behavior says its running.
    local s = childStatus

    while true do
        if not bFirst or s == EBTStatus.BT_RUNNING then
            local indexSet = self:getIndexSet(tick)
            local childIndex = indexSet[activeChildIndex]
            local pChild = self.m_children[childIndex]

            if self:checkIfInterrupted(agent, tick) then
                return EBTStatus.BT_FAILURE
            end

            s = tick:exec(pChild, agent)
        end

        bFirst = false
        --  If the child fails, or keeps running, do the same.
        if s ~= EBTStatus.BT_SUCCESS then
            return s
        end

        --  Hit the end of the array, job done!
        activeChildIndex = activeChildIndex + 1
        self:setActiveChildIndex(tick, activeChildIndex)
        if activeChildIndex > #self.m_children then
            return EBTStatus.BT_SUCCESS
        end
    end
end

return _M