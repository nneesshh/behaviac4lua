--- Behaviac lib Component: precondition config.
-- @module PreconditionConfig.lua
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
local PreconditionConfig = class("PreconditionConfig", AttachActionConfig)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("PreconditionConfig", PreconditionConfig)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("PreconditionConfig", "AttachActionConfig")
local _M = PreconditionConfig

--------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_phase  = EPreconditionPhase.E_ENTER
    self.m_bAnd   = false
    self.__name   =  "PreconditionConfig"
end

function _M:load(properties)
    local loaded = _M.super.load(self, properties)

    for _, p in ipairs(properties) do
        local binaryOpStr = p["BinaryOperator"]
        local phaseStr = p["Phase"]

        if nil ~= binaryOpStr then
            if binaryOpStr == "Or" then
                self.m_bAnd = false
            elseif binaryOpStr == "And" then
                self.m_bAnd = true
            else
                _G.BEHAVIAC_ASSERT(false, "[_M:load()] BinaryOperator")
            end
        elseif nil ~= phaseStr then
            if phaseStr == "Enter" then
                self.m_phase = EPreconditionPhase.E_ENTER
            elseif phaseStr == "Update" then
                self.m_phase = EPreconditionPhase.E_UPDATE
            elseif phaseStr == "Both" then
                self.m_phase = EPreconditionPhase.E_BOTH
            else
                _G.BEHAVIAC_ASSERT(false, "[_M:load()] Phase")
            end
            break
        end
    end
end

return _M