--- Behaviac lib Component: attach action attachements node.
-- @module AttachAction.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

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
local BaseNode = require(pdir .. "core.BaseNode")
local AttachAction = class("AttachAction", BaseNode)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("AttachAction", AttachAction)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("AttachAction", "BaseNode")
local _M = AttachAction

local AttachActionConfig = require(cwd .. "AttachActionConfig")
local NodeParser = require(pdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_ActionConfig = false
end

function _M:release()
    _M.super.release(self)

    self.m_ActionConfig = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)
    
    self.m_ActionConfig:parse(properties)
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:evaluate(agent, tick)
    local bValid = self.m_ActionConfig:execute(agent, tick)
    if not bValid then
        childStatus = EBTStatus.BT_INVALID
        bValid = (EBTStatus.BT_SUCCESS == self:evaluateImpl(agent, tick, childStatus))
    end

    return bValid
end

function _M:evaluateWithStatus(agent, tick, status)
    -- BEHAVIAC_UNUSED_VAR status
    local bValid = self.m_ActionConfig:execute(agent, tick)
    if not bValid then
        childStatus = EBTStatus.BT_INVALID
        bValid = (EBTStatus.BT_SUCCESS == self:evaluateImpl(agent, tick, childStatus))
    end

    return bValid
end

return _M