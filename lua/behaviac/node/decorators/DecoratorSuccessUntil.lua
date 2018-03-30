--- Behaviac lib Component: success until decorator node.
-- @module DecoratorSuccessUntil.lua
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
-- DecoratorSuccessUntil node always return Success until it reaches a specified number of count.
-- when reach time exceed the count specified return Failure. If the specified number of count
-- is -1, then always return Success.
-- Returns BT_SUCCESS for the specified number of iterations, then returns BT_FAILURE after that
local DecoratorCount = require(cwd .. "DecoratorCount")
local DecoratorSuccessUntil = class("DecoratorSuccessUntil", DecoratorCount)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorSuccessUntil", DecoratorSuccessUntil)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorSuccessUntil", "DecoratorCount")
local _M = DecoratorSuccessUntil

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

function _M:isDecoratorSuccessUntil()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:onEnter(agent, tick)
    -- don't reset the m_n if it is restarted
    local num = self:getNum(tick)
    if num == 0 then
        local countP = self:getCountP()
        if countP == 0 then
            return false
        end
        self:senNum(tick, countP)
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
        if n == 0 then
            return EBTStatus.BT_FAILURE
        end
        return EBTStatus.BT_SUCCESS
    end

    if n == -1 then
        return EBTStatus.BT_SUCCESS
    end

    _G.BEHAVIAC_ASSERT(n == 0, "[_M:decorate()] n == 0")
    return EBTStatus.BT_FAILURE
end

return _M