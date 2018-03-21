--- Behaviac lib Component: count once decorator node.
-- @module DecoratorCountOnce.lua
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
local DecoratorCount = require(cwd .. "DecoratorCount")
local DecoratorCountOnce = class("DecoratorCountOnce", DecoratorCount)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorCountOnce", DecoratorCountOnce)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorCountOnce", "DecoratorCount")
local _M = DecoratorCountOnce

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

function _M:checkIfReInit(agent)
    return self:evaluteCustomCondition(agent)
end

function _M:isDecoratorCountOnce()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)

    self:setInitialized(tick, false)
    self:setRunOnce(tick, false)
end

function _M:onEnter(agent, tick)
    local bRunOnce = self:getRunOnce(tick)
    if bRunOnce then
        return false
    end

    if self.m_status == EBTStatus.BT_RUNNING then
        return true
    end

    if self.checkIfReInit(agent) then
        self:setInitialized(tick, false)
    end

    local bInitialized = self:getInitialized(tick)
    local num = self:getNum(tick)
    if not bInitialized then
        self:setInitialized(tick, true)
        local countP = self:getCountP(agent)
        self:setNum(countP)

        num = self:getNum(tick)
        _G.BEHAVIAC_ASSERT(num > 0, "[_M:onEnter()] false num > 0")
    end

    -- if self.m_n is -1, it is endless
    if num > 0 then
        num = num - 1
        self:setNum(tick, num)
        return true
    elseif num == 0 then
        self:setRunOnce(tick, true)
        return false
    elseif num == -1 then
        self:setRunOnce(tick, true)
        return true
    end
    _G.BEHAVIAC_ASSERT(false, "[_M:onEnter()] false")
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

function _M:setRunOnce(tick, b)
    tick:setNodeMem("runOnce", b, self)
end

function _M:getRunOnce(tick)
    return tick:getNodeMem("runOnce", self)
end

return _M