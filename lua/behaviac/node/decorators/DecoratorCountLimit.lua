--- Behaviac lib Component: count limit decorator node.
-- @module DecoratorCountLimit.lua
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
-- DecoratorCountLimit can be set a integer Count limit value. DecoratorCountLimit node tick its child until
-- inner count less equal than count limit value. Whether node increase inner count depend on
-- the return value of its child when it updates. if DecorateChildEnds flag is true, node increase count
-- only when its child node return value is Success or Failure. The inner count will never reset until
-- attachment on the node evaluate true.
local DecoratorCount = require(cwd .. "DecoratorCount")
local DecoratorCountLimit = class("DecoratorCountLimit", DecoratorCount)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorCountLimit", DecoratorCountLimit)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorCountLimit", "DecoratorCount")
local _M = DecoratorCountLimit

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

function _M:isDecoratorCountLimit()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)

    self:setInitialized(tick, false)
end

function _M:onEnter(agent, tick)
    if self:checkIfReInit(agent) then
        self:setInitialized(tick, false)
    end

    local bInitialized = self:getInitialized(tick)
    if not bInitialized then
        self:setInitialized(tick, true)
        local countP = self:getCountP(agent)
        self:setNum(tick, countP)
    end

    -- if self.m_n is -1, it is endless
    local num = self:getNum(tick)
    if num > 0 then
        num = num - 1
        self:setNum(tick, num)
        return true
    elseif num == 0 then
        return false
    elseif num == -1 then
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

return _M