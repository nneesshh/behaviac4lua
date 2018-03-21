--- Behaviac lib Component: precondition attachements node.
-- @module Precondition.lua
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
local Precondition = class("Precondition", AttachAction)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Precondition", Precondition)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Precondition", "AttachAction")
local _M = Precondition

local PreconditionConfig = require(cwd .. "PreconditionConfig")
local NodeParser = require(pdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_ActionConfig = PreconditionConfig.new()
end

function _M:release()
    _M.super.release(self)

    self.m_ActionConfig = false
end

function _M:getPhase()
    return self.m_ActionConfig.m_phase
end

function _M:setPhase(phase)
    self.m_ActionConfig.m_phase = phase
end

function _M:isAnd()
    return self.m_ActionConfig.m_bAnd
end

function _M:setIsAnd(isAnd)
    self.m_ActionConfig.m_bAnd = isAnd
end

function _M:isPrecondition()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

return _M