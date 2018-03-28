--- Behaviac lib Component: time decorator node.
-- @module DecoratorLog.lua
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
-- Output message specified when it updates.
local Decorator = require(ppdir .. "core.Decorator")
local DecoratorLog = class("DecoratorLog", Decorator)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorLog", DecoratorLog)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorLog", "Decorator")
local _M = DecoratorLog

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_message = ""
end

function _M:release()
    _M.super.release(self)
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "Log" then
            self.m_message = valueStr
        end
    end
end

function _M:isDecoratorLog()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:decorate(status, tick)
    _G.BEHAVIAC_ASSERT(self:isDecoratorLog(), "[_M:decorate()] self:isDecoratorLog")
    --_G.BEHAVIAC_LOGINFO("DecoratorLogTask:%s\n", self.m_message)
    Logging.error("DecoratorLog:%s\n", self.m_message)
    return status
end

return _M