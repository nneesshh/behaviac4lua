--- Behaviac lib Component: sequence composite node.
-- @module Sequence.lua
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
-- Sequences tick each of their children one at a time from top to bottom. If a child returns Failure,
-- so does the Sequence. If it returns Success, the Sequence will move on to the next child in line
-- and return Running.If a child returns Running, so does the Sequence and that same child will be
-- ticked again next time the Sequence is ticked.Once the Sequence reaches the end of its child list,
-- it returns Success and resets its child index meaning the first child in the line will be ticked
-- on the next tick of the Sequence.
local Composite = require(ppdir .. "core.Composite")
local Sequence = class("Sequence", Composite)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Sequence", Sequence)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Sequence", "Composite")
local _M = Sequence

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

function _M:sequenceUpdate(agent, tick, childStatus, activeChildIndex, children)
    local s = childStatus
    local childSize = #children

    _G.BEHAVIAC_ASSERT(activeChildIndex >= 1 and activeChildIndex <= childSize)

    while true do
        _G.BEHAVIAC_ASSERT(activeChildIndex <= childSize, "[_M:SequenceUpdate()] activeChildIndex <= childSize")

        if s == EBTStatus.BT_RUNNING then
            local pChild = children[activeChildIndex]

            if self:checkIfInterrupted(agent, tick) then
                return EBTStatus.BT_FAILURE, activeChildIndex
            end

            s = tick:exec(pChild, agent)
        end

        --  If the child fails, or keeps running, do the same.
        if s ~= EBTStatus.BT_SUCCESS then
            return s, activeChildIndex
        end

        --  Hit the end of the array, job done!
        activeChildIndex = activeChildIndex + 1
        
        if activeChildIndex > childSize then
            return EBTStatus.BT_SUCCESS, activeChildIndex
        end

        s = EBTStatus.BT_RUNNING
    end
end

function _M:checkIfInterrupted(agent, tick)
    return self:evaluteCustomCondition(agent, tick)
end

function _M:isSequence()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:onEnter(agent, tick)
    self:setActiveChildIndex(tick, 1)
    return true
end

function _M:update(agent, tick, childStatus)
    local activeChildIndex = self:getActiveChildIndex(tick)
    _G.BEHAVIAC_ASSERT(activeChildIndex <= #self.m_children, "[_M:update()] activeChildIndex <= #self.m_children")

    local outStatus, outActiveChildIndex = self:sequenceUpdate(agent, tick, childStatus, activeChildIndex, self.m_children)
    self:setActiveChildIndex(tick, outActiveChildIndex)
    return outStatus
end

function _M:evaluate(agent, tick)
    local ret = true    
    for _, child in ipairs(self.m_children) do
        ret = child:evaluate(agent, tick)
        if not ret then
            break
        end
    end

    return ret
end

return Sequence