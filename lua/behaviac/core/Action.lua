--- Behaviac lib Component: action node.
-- @module Action.lua
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
-- Action node is the bridge between behavior tree and agent member function. Agent 
-- member function can be assigned to an action node, and will be invoked when the 
-- action node ticked. Agent member function attached to action node can be up to 
-- eight parameters most.
local Leaf = require(cwd .. "Leaf")
local Action = class("Action", Leaf)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Action", Action)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Action", "Leaf")
local _M = Action

local NodeParser = require(pdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_method         = false
    self.m_resultFunctor  = false
    self.m_resultOption   = EBTStatus.BT_INVALID
end

function _M:release()
    _M.super.release(self)

    self.m_method         = false
    self.m_resultFunctor  = false
end

-- 
function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "Method" then
            self.m_method = NodeParser.parseMethod(valueStr)
        elseif nameStr == "ResultOption" then
            if valueStr == "BT_INVALID" then
                self.m_resultOption = EBTStatus.BT_INVALID
            elseif valueStr == "BT_FAILURE" then
                self.m_resultOption = EBTStatus.BT_FAILURE
            elseif valueStr == "BT_RUNNING" then
                self.m_resultOption = EBTStatus.BT_RUNNING
            else
                self.m_resultOption = EBTStatus.BT_SUCCESS
            end
        elseif nameStr == "ResultFunctor" then
            self.m_resultFunctor = NodeParser.parseMethod(valueStr)
        else
            -- do nothing
        end
    end
end

function _M:isAction()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:onEnter(agent, tick)
    return true
end

function _M:onExit(agent, tick, status)
    return true
end

function _M:update(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(self:isAction(), "[_M:update()] self:isAction()")

    return self:executeAction(agent, tick, childStatus)
end

--
function _M:execute(agent, tick)
    local status = EBTStatus.BT_RUNNING
    if self.m_method then
        self.m_method:run(agent, tick)
    else
        status = self:evaluateImpl(agent, tick, EBTStatus.BT_RUNNING)
    end

    return status
end

--
function _M:executeAction(agent, tick, childStatus)
    local status = EBTStatus.BT_SUCCESS
    if self.m_method then
        if self.m_resultOption ~= EBTStatus.BT_INVALID then
            self.m_method:run(agent, tick)
            status = self.m_resultOption
        else
            local val = nil
            if self.m_resultFunctor then
                val = self.m_resultFunctor:getValueFrom(agent, tick, self.m_method)
            else
                val = self.m_method:getValue(agent, tick)
            end
            status = val and tonumber(val) or EBTStatus.BT_FAILURE
        end
    else
        status = self:evaluateImpl(agent, tick, childStatus)
    end
    return status
end

return _M