--- Behaviac lib Component: attach action config.
-- @module AttachActionConfig.lua
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
local AttachActionConfig = class("AttachActionConfig")
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("AttachActionConfig", AttachActionConfig)
local _M = AttachActionConfig

local NodeParser = require(pdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    self.m_opl         = false
    self.m_opr1        = false
    self.m_operator    = EOperatorType.E_INVALID
    self.m_opr2        = false
    self.__name        = "AttachActionConfig"

    --self.m_comparator  = false
end

function _M:load(properties)
    for _, p in ipairs(properties) do
        local opLeftStr = p["Opl"]
        local opRightStr1 = p["Opr1"]
        local opStr = p["operator"]
        local opRightStr2 = p["Opr2"]

        if nil ~= opLeftStr then
            if StringUtils.isValidString(opLeftStr) then
                local pParenthesis = string.find(opLeftStr, '%(')
                if not pParenthesis then
                    self.m_opl = NodeParser.parseProperty(opLeftStr)
                else
                    self.m_opl = NodeParser.parseMethod(opLeftStr)
                end
            end
        elseif nil ~= opRightStr1 then
            if StringUtils.isValidString(opRightStr1) then
                local pParenthesis = string.find(opRightStr1, '%(')
                if not pParenthesis then
                    self.m_opr1 = NodeParser.parseProperty(opRightStr1)
                else
                    self.m_opr1 = NodeParser.parseMethod(opRightStr1)
                end
            end
        elseif nil ~= opStr then
            self.m_operator = NodeParser.parseOperatorType(opStr)
        elseif nil ~= opRightStr2 then
            if StringUtils.isValidString(opRightStr2) then
                local pParenthesis = string.find(opRightStr2, '%(')
                if not pParenthesis then
                    self.m_opr2 = NodeParser.parseProperty(opRightStr2)
                else
                    self.m_opr2 = NodeParser.parseMethod(opRightStr2)
                end
            end
        else
            -- _G.BEHAVIAC_ASSERT(0, "unrecognized property")
        end
    end

    return self.m_opl
end

function _M:execute(agent)
    local bValid = false
    -- action
    if self.m_opl and self.m_operator == EOperatorType.E_INVALID then
        bValid = true
        if self.m_opl.run then
            self.m_opl:run(agent)
        end
    -- assign
    elseif self.m_operator == EOperatorType.E_ASSIGN then
        if self.m_opl then
            self.m_opl:setValueCast(agent, self.m_opr2, false)
            bValid = true
        end
    -- compute
    elseif self.m_operator >= EOperatorType.E_ADD and self.m_operator <= EOperatorType.E_DIV then
        if self.m_opl then
            self.m_opl:compute(agent, self.m_opr1, self.m_opr2, self.m_operator)
            bValid = true
        end
    -- compare
    elseif self.m_operator >= EOperatorType.E_EQUAL and self.m_operator <= EOperatorType.E_LESSEQUAL then
        if self.m_opl then
            bValid = self.m_opl:compare(agent, self.m_opr2, self.m_operator)
        end
    end
    return bValid
end

return _M