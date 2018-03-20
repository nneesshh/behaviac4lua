--- Behaviac lib Component: loop until decorator node.
-- @module DecoratorLoopUntil.lua
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
-- DecoratorLoopUntil node always return Failure until it reaches a specified number of count.
-- when reach time exceed the count specified return Success. If the specified number of count
-- is -1, then always return failed
-- Returns BT_FAILURE for the specified number of iterations, then returns BT_SUCCESS after that
local DecoratorCount = require(cwd .. "DecoratorCount")
local DecoratorLoopUntil = class("DecoratorLoopUntil", DecoratorCount)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorLoopUntil", DecoratorLoopUntil)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorLoopUntil", "DecoratorCount")
local _M = DecoratorLoopUntil

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_until = false
end

function _M:release()
    _M.super.release(self)
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    for _, p in ipairs(properties) do
        local untilStr = p["Until"]

        if nil ~= untilStr then
            self.m_until = (untilStr == "true")
        end
    end
end

function _M:isDecoratorLoopUntil()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:decorate(status, tick)
    local num = self:getNum(tick)
    if num > 0 then
        num = num - 1
        self:setNum(tick, num)
    end

    if n == 0 then
        return EBTStatus.BT_SUCCESS
    end

    _G.BEHAVIAC_ASSERT(self:isDecoratorLoopUntil(), "[_M:decorate()] self:isDecoratorLoopUntil")
    if self.m_until then
        if status == EBTStatus.BT_SUCCESS then
            return EBTStatus.BT_SUCCESS
        end
    else
        if status == EBTStatus.BT_FAILURE then
            return EBTStatus.BT_FAILURE
        end
    end

    return EBTStatus.BT_RUNNING
end

return _M