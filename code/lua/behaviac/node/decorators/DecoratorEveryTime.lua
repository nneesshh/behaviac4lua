--- Behaviac lib Component: every time decorator node.
-- @module DecoratorEveryTime.lua
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
local EPreDecoratorPhase        = enums.EPreDecoratorPhase
local TriggerMode               = enums.TriggerMode
local EOperatorType             = enums.EOperatorType

local constSupportedVersion     = enums.constSupportedVersion
local constInvalidChildIndex    = enums.constInvalidChildIndex
local constBaseKeyStrDef        = enums.constBaseKeyStrDef
local constPropertyValueType    = enums.constPropertyValueType

local Logging                   = common.d_log
local StringUtils               = common.StringUtils

-- Class
-- Execute intervally
local DecoratorTime = require(cwd .. "DecoratorTime")
local DecoratorEveryTime = class("DecoratorEveryTime", DecoratorTime)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorEveryTime", DecoratorEveryTime)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorEveryTime", "DecoratorTime")
local _M = DecoratorEveryTime

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

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)

    self:setInitialized(tick, false)
    self:setStart(tick, 0)
    self:setTime(tick, 0)
end

function _M:onEnter(agent, tick)
    local bInitialized = self:getInitialized(tick)
    if bInitialized then
        local status = self:getStatus(tick)
        if status == EBTStatus.BT_RUNNING then
            return true
        else
            return self:checkTime(agent)
        end
    end

    if _M.super.onEnter(self, agent, tick) then
        self:setInitialized(tick, true)
        return self:checkTime(agent)
    else
        return false
    end
end

function _M:checkTime(agent)
    local time = comm.getColock()
    if time - self:getStart(tick) >= self:getTime(tick) then
        self:setStart(tick, time)
        return true
    end

    return false
end

function _M:decorate(status, tick)
    return status
end

function _M:setInitialized(tick, b)
    tick:setNodeMem("initialized", b, self)
end

function _M:getInitialized(tick)
    return tick:getNodeMem("initialized", self)
end

function _M:setStart(tick, n)
    tick:setNodeMem("start", n, self)
end

function _M:getStart(tick)
    return tick:getNodeMem("start", self)
end

function _M:setTime(tick, tm)
    tick:setNodeMem("time", tm, self)
end

function _M:getTime(tick)
    return tick:getNodeMem("time", self)
end

return _M