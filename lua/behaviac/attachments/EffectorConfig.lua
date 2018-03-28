--- Behaviac lib Component: effector config.
-- @module EffectorConfig.lua
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
local AttachActionConfig = require(cwd .. "AttachActionConfig")
local EffectorConfig = class("EffectorConfig", AttachActionConfig)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("EffectorConfig", EffectorConfig)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("EffectorConfig", "AttachActionConfig")
local _M = EffectorConfig

--------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_phase = ENodePhase.E_SUCCESS
end

function _M:parse(properties)
    local success = _M.super.parse(self, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "Phase" then
            if valueStr == "Success" then
                self.m_phase = ENodePhase.E_SUCCESS
            elseif valueStr == "Failure" then
                self.m_phase = ENodePhase.E_FAILURE
            elseif valueStr == "Both" then
                self.m_phase = ENodePhase.E_BOTH
            else
                _G.BEHAVIAC_ASSERT(false)
            end
            break
        end
    end
    return success
end

return _M