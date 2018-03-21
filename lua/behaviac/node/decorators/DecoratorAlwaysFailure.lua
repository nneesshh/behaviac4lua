--- Behaviac lib Component: always failure decorator node.
-- @module DecoratorAlwaysFailure.lua
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
-- No matter what child return. DecoratorAlwaysFailure always return Failure. it can only has one child node.
local Decorator = require(ppdir .. "core.Decorator")
local DecoratorAlwaysFailure = class("DecoratorAlwaysFailure", Decorator)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorAlwaysFailure", DecoratorAlwaysFailure)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorAlwaysFailure", "Decorator")
local _M = DecoratorAlwaysFailure

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

function _M:decorate(status, tick)
    return EBTStatus.BT_FAILURE
end

return _M