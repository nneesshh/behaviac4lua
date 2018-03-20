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

function _M:load(properties)
    local loaded = _M.super.load(self, properties)

    for _, p in ipairs(properties) do
        local phaseStr = p["Phase"]

        if nil ~= phaseStr then
            if phaseStr == "Success" then
                self.m_phase = ENodePhase.E_SUCCESS
            elseif phaseStr == "Failure" then
                self.m_phase = ENodePhase.E_FAILURE
            elseif phaseStr == "Both" then
                self.m_phase = ENodePhase.E_BOTH
            else
                _G.BEHAVIAC_ASSERT(false)
            end
            break
        end
    end
    return loaded
end

function _M:release()
    _M.super.release(self)
end

return _M