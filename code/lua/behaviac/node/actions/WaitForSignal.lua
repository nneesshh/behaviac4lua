--- Behaviac lib Component: Wait for signal action node.
-- @module WaitForSignal.lua
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
-- Always return Running until the predicates of WaitForSignalforSignal node become true,
-- or executing child node and return execution result.
local BaseNode = require(ppdir .. "core.BaseNode")
local WaitForSignal = class("WaitForSignal", BaseNode)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("WaitForSignal", WaitForSignal)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("WaitForSignal", "BaseNode")
local _M = WaitForSignal

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

function _M:checkIfSignaled(agent)
    return self:evaluteCustomCondition(agent)
end

function _M:isWaitForSignal()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    self:setTriggered(tick, false)
end

function _M:onEnter(agent, tick)
    self:setTriggered(tick, false)
    return true
end

function _M:onExit(agent, tick)
end

function _M:update(agent, tick, childStatus)
    if childStatus ~= EBTStatus.BT_RUNNING then
        return childStatus
    end

    local bTriggered = self:getTriggered(tick)
    if not bTriggered then
        self:setTriggered(tick, self:checkIfSignaled(agent))
    end

    bTriggered = self:getTriggered(tick)
    if bTriggered then
        if not self.m_root then
            return EBTStatus.BT_SUCCESS
        end
        return _M.super.update(agent, tick, childStatus)
    end

    return EBTStatus.BT_RUNNING
end

function _M:setTriggered(tick, b)
    tick:setNodeMem("triggered", b, self)
end

function _M:getTriggered(tick)
    return tick:getNodeMem("triggered", self)
end

return _M