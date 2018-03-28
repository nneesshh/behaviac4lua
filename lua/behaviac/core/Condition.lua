--- Behaviac lib Component: condition node.
-- @module Condition.lua
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
local Leaf = require(cwd .. "Leaf")
local Condition = class("Condition", Leaf)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Condition", Condition)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Condition", "Leaf")
local _M = Condition

local NodeParser = require(pdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_opl      = false
    self.m_opr      = false
    self.m_operator = EOperatorType.E_EQUAL
end

function _M:release()
    _M.super.release(self)

    self.m_opl      = false
    self.m_opr      = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "Operator" then
            self.m_operator = NodeParser.parseOperatorType(valueStr)
        elseif nameStr == "Opl" then
            local pParenthesis = string.find(valueStr, '%(')
            if not pParenthesis then
                self.m_opl = NodeParser.parseProperty(valueStr)
            else
                self.m_opl = NodeParser.parseMethod(valueStr)
            end
        elseif nameStr == "Opr" then
            local pParenthesis = string.find(valueStr, '%(')
            if not pParenthesis then
                self.m_opr = NodeParser.parseProperty(valueStr)
            else
                self.m_opr = NodeParser.parseMethod(valueStr)
            end
        else
            -- maybe others
        end
    end
end

function _M:isCondition()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:onEnter(agent, tick)
    return true
end

function _M:onExit(agent, tick, status)
end

function _M:update(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(self:isCondition(), "[_M:update()] self:isCondition")

    if self:evaluate(agent, tick) then
        return EBTStatus.BT_SUCCESS
    else
        return EBTStatus.BT_FAILURE
    end
end

function _M:evaluate(agent, tick)
    if self.m_opl and self.m_opr then
        return self.m_opl:compare(agent, self.m_opr, self.m_operator)
    else
        local result = self:evaluateImpl(agent, tick, EBTStatus.BT_INVALID)
        return result == EBTStatus.BT_SUCCESS
    end
end

return _M