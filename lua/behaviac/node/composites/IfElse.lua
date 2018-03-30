--- Behaviac lib Component: if else composite node.
-- @module IfElse.lua
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
-- This node has three children: 'condition' branch, 'if' branch, 'else' branch. first, it executes
-- conditon, until it returns success or failure. if it returns success, it then executes 'if' branch,
-- else if it returns failure, it then executes 'else' branch.
local Composite = require(ppdir .. "core.Composite")
local Cls_IfElse = class("IfElse", Composite)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("IfElse", Cls_IfElse)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("IfElse", "Composite")
local _M = Cls_IfElse

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)
end

function _M:release()
    _M.super.release(self)
end

function _M:isIfElse()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:onEnter(agent, tick)
    self:setActiveChildIndex(tick, constInvalidChildIndex)
    if #self.m_children == 3 then
        return true
    end

    _G.BEHAVIAC_ASSERT(false, "IfElse has to have three children: condition, if, else")
    return false
end

function _M:onExit(agent, tick, status)
end

function _M:update(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(childStatus ~= EBTStatus.BT_INVALID, "[_M:update()] childStatus ~= EBTStatus.BT_INVALID")
    _G.BEHAVIAC_ASSERT(#self.m_children == 3, "[_M:update()] #self.m_children == 3")

    local conditionResult = EBTStatus.BT_INVALID

    if childStatus == EBTStatus.BT_SUCCESS or childStatus == EBTStatus.BT_FAILURE then
        -- if the condition returned running then ended with childStatus
        conditionResult = childStatus
    end

    local activeChildIndex = self:getActiveChildIndex(tick)
    if activeChildIndex == constInvalidChildIndex then
        local pCondition = self.m_children[1]
        if conditionResult == EBTStatus.BT_INVALID then
            -- condition has not been checked
            conditionResult = tick:exec(pCondition, agent)
        end

        if conditionResult == EBTStatus.BT_SUCCESS then
            -- if
            activeChildIndex = 2
            self:setActiveChildIndex(tick, activeChildIndex)
        elseif conditionResult == EBTStatus.BT_FAILURE then
            -- else
            activeChildIndex = 3
            self:setActiveChildIndex(tick, activeChildIndex)
        end
    else
        return childStatus
    end

    if activeChildIndex ~= constInvalidChildIndex then
        local pChild = self.m_children[activeChildIndex]
        local s = tick:exec(pChild, agent)
        return s
    end

    return EBTStatus.BT_RUNNING
end

return _M