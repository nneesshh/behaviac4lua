--- Behaviac lib Component: always running decorator node.
-- @module DecoratorAlwaysRunning.lua
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
-- No matter what child return. DecoratorAlwaysRunning always return Running. it can only has one child node.
local Decorator = require(ppdir .. "core.Decorator")
local DecoratorAlwaysRunning = class("DecoratorAlwaysRunning", Decorator)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorAlwaysRunning", DecoratorAlwaysRunning)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorAlwaysRunning", "Decorator")
local _M = DecoratorAlwaysRunning

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

function _M:isDecoratorAlwaysRunning()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:decorate(status, tick)
    return EBTStatus.BT_RUNNING
end

return _M