--- Behaviac lib Component: failure until decorator node.
-- @module DecoratorFailureUntil.lua
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
-- DecoratorFailureUntil node always return Failure until it reaches a specified number of count.
-- when reach time exceed the count specified return Success. If the specified number of count
-- is -1, then always return failed
-- Returns BT_FAILURE for the specified number of iterations, then returns BT_SUCCESS after that
local DecoratorCount = require(cwd .. "DecoratorCount")
local DecoratorFailureUntil = class("DecoratorFailureUntil", DecoratorCount)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorFailureUntil", DecoratorFailureUntil)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorFailureUntil", "DecoratorCount")
local _M = DecoratorFailureUntil

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

function _M:isDecoratorFailureUntil()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:onEnter(agent, tick)
    -- don't reset the m_n if it is restarted
    local num = self:getNum(tick)
    if num == 0  then
        local countP = self:getCountP(agent)
        if countP == 0 then
            return false
        end

        self:setNum(countP)
    else
        -- do nothing
    end

    return true
end

function _M:decorate(status, tick)
    local num = self:getNum(tick)
    if num > 0 then
        num = num - 1
        self:setNum(tick, num)
        if num == 0 then
            return EBTStatus.BT_SUCCESS
        end

        return EBTStatus.BT_FAILURE
    end

    if num == -1 then
        return EBTStatus.BT_FAILURE
    end

    _G.BEHAVIAC_ASSERT(num == 0, "[_M:decorate()] num == 0")
    return EBTStatus.BT_SUCCESS
end

return _M