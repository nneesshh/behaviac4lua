--- Behaviac lib Component: decorator node.
-- @module Decorator.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11
-- Localize

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."
local enums = require(pdir .. "enums")
local common = require(pdir .. "common")

local EBTStatus                 = enums.EBTStatus
local ENodePhase                = enums.ENodePhase
local EPreconditionPhase        = enums.EPreconditionPhase
local TriggerMode               = enums.TriggerMode
local EOperatorType             = enums.EOperatorType

local constSupportedVersion     = enums.constSupportedVersion
local constInvalidChildIndex    = enums.constInvalidChildIndex
local constBaseKeyStrDef        = enums.constBaseKeyStrDef
local constPropertyValueType    = enums.constPropertyValueType

local Logging                   = common.d_log
local StringUtils               = common.StringUtils

-- Class
local SingleChild = require(cwd .. "SingleChild")
local Decorator = class("Decorator", SingleChild)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Decorator", Decorator)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Decorator", "SingleChild")
local _M = Decorator

local NodeParser = require(pdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_bDecorateWhenChildEnds = false
end

function _M:release()
    _M.super.release(self)
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    for _, p in ipairs(properties) do
        local decorateWhenChildEndsStr = p["DecorateWhenChildEnds"]

        if nil ~= decorateWhenChildEndsStr then
            if decorateWhenChildEndsStr == "true" then
                self.m_bDecorateWhenChildEnds = true
            end
        else
        end
    end
end

function _M:isManagingChildrenAsSubTrees()
    return true
end

function _M:isDecorator()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(node)
    _M.super.init(self, node)

end

function _M:onEnter(agent, tick)
    return true
end

function _M:update(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(self:isDecorator(), "[_M:update()] isDecorator")
    local status = EBTStatus.BT_INVALID
    if childStatus ~= EBTStatus.BT_RUNNING then
        status = childStatus
        if not self.m_bDecorateWhenChildEnds or status ~= EBTStatus.BT_RUNNING then
            local result = self:decorate(status, tick)
            if result ~= EBTStatus.BT_RUNNING then
                return result
            end
            
            return EBTStatus.BT_RUNNING
        end
    end

    status = _M.super.update(self, agent, tick, childStatus)
    if not self.m_bDecorateWhenChildEnds or status ~= EBTStatus.BT_RUNNING then
        local result = self:decorate(status, tick)
        if result ~= EBTStatus.BT_RUNNING then
            return result
        end
    end
    return EBTStatus.BT_RUNNING
end

-- called when the child's exec returns success or failure.
-- please note, it is not called if the child's exec returns running
function _M:decorate(status, tick)
    -- _G.BEHAVIAC_UNUSED_VAR status
    Logging.error("derived class must be rewrite _M:decorate")
    return EBTStatus.BT_RUNNING
end

return _M