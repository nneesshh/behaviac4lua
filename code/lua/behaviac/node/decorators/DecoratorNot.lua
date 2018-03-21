--- Behaviac lib Component: not decorator node.
-- @module DecoratorNot.lua
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
-- DecoratorNot node inverts the return value of child. But keeping the Running value unchanged.
local Decorator = require(ppdir .. "core.Decorator")
local DecoratorNot = class("DecoratorNot", Decorator)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorNot", DecoratorNot)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorNot", "Decorator")
local _M = DecoratorNot

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

function _M:evaluate(agent, tick)
    _G.BEHAVIAC_ASSERT(#self.m_children == 1, "[_M:evaluate()] #self.m_children == 1")
    return not self.m_children[1]:evaluate(agent, tick)
end

function _M:isDecoratorNot()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:decorate(status, tick)
    if status == EBTStatus.BT_FAILURE then
        return EBTStatus.BT_SUCCESS
    end

    if status == EBTStatus.BT_SUCCESS then
        return EBTStatus.BT_FAILURE
    end

    return status
end

return _M