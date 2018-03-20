--- Behaviac lib Component: weight decorator node.
-- @module DecoratorWeight.lua
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
local Decorator = require(ppdir .. "core.Decorator")
local DecoratorWeight = class("DecoratorWeight", Decorator)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorWeight", DecoratorWeight)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorWeight", "Decorator")
local _M = DecoratorWeight

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_weight = false
end

function _M:release()
    _M.super.release(self)
    
    self.m_weight = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    for _, p in ipairs(properties) do
        local weightStr = p["Weight"]

        if nil ~= weightStr then
            self.m_weight = BehaviorParseFactory.parseProperty(weightStr)
        end
    end
end

function _M:getWeight(agent)
    return self.m_weight and self.m_weight:getValue(agent) or 0
end

function _M:isManagingChildrenAsSubTrees()
    return false
end

function _M:isDecoratorWeight()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:decorate(status, tick)
    return status
end

return _M