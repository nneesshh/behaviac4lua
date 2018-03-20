--- Behaviac lib Component: always success decorator node.
-- @module DecoratorAlwaysSuccess.lua
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
-- No matter what child return. DecoratorAlwaysSuccess always return Success. it can only has one child node.
local Decorator = require(ppdir .. "core.Decorator")
local DecoratorAlwaysSuccess = class("DecoratorAlwaysSuccess", Decorator)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorAlwaysSuccess", DecoratorAlwaysSuccess)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorAlwaysSuccess", "Decorator")
local _M = DecoratorAlwaysSuccess

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

function _M:isDecoratorAlwaysSuccess()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:decorate(status, tick)
    return EBTStatus.BT_SUCCESS
end

return _M