--- Behaviac lib Component: compute action node.
-- @module Compute.lua
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
-- Compute the result of Operand1 and Operand2 and assign it to the Left Operand.
-- Compute node can perform Add, Sub, Mul and Div operations. a left and right Operand
-- can be a agent property or a par value.
local Leaf = require(ppdir .. "core.Leaf")
local Compute = class("Compute", Leaf)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Compute", Compute)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Compute", "Leaf")
local _M = Compute

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_opl      = false
    self.m_opr1     = false
    self.m_opr2     = false
    self.m_operator = EOperatorType.E_INVALID
end

function _M:release()
    _M.super.release(self)

    self.m_opl      = false
    self.m_opr1     = false
    self.m_opr2     = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "Opl" then
            self.m_opl = NodeParser.parseProperty(valueStr)
        elseif nameStr == "Operator" then
            self.m_operator = NodeParser.parseOperatorType(valueStr)
        elseif nameStr == "Opr1" then
            local pParenthesis = string.find(valueStr, '%(')
            if not pParenthesis then
                self.m_opr1 = NodeParser.parseProperty(valueStr)
            else
                self.m_opr1 = NodeParser.parseMethod(valueStr)
            end
        elseif nameStr == "Opr2" then
            local pParenthesis = string.find(valueStr, '%(')
            if not pParenthesis then
                self.m_opr2 = NodeParser.parseProperty(valueStr)
            else
                self.m_opr2 = NodeParser.parseMethod(valueStr)
            end
        else
            -- do nothing
        end
    end
end

function _M:isCompute()
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
    _G.BEHAVIAC_ASSERT(childStatus == EBTStatus.BT_RUNNING, "[_M:update()] childStatus == EBTStatus.BT_RUNNING")
    _G.BEHAVIAC_ASSERT(self:isCompute(), "[_M:update()] self:isCompute()")

    local status = EBTStatus.BT_SUCCESS

    if self.m_opl then
        self.m_opl:compute(agent, self.m_opr1, self.m_opr2, self.m_operator)
    else
        status = self:evaluateImpl(agent, tick, childStatus)
    end
    
    return status
end

return _M