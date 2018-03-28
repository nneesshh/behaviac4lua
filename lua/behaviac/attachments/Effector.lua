--- Behaviac lib Component: effector attachements node.
-- @module Effector.lua
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
local AttachAction = require(cwd .. "AttachAction")
local Effector = class("Effector", AttachAction)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Effector", Effector)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Effector", "AttachAction")
local _M = Effector

local EffectorConfig = require(cwd .. "EffectorConfig")
local NodeParser = require(pdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_ActionConfig = EffectorConfig.new()
end

function _M:release()
    _M.super.release(self)
end

function _M:getPhase()
    return self.m_ActionConfig.m_phase
end

function _M:setPhase(phase)
    self.m_ActionConfig.m_phase = phase
end

function _M:isEffector()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

return _M