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
local BaseNode = require(cwd .. "BaseNode")
local Action = class("Action", BaseNode)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Action", Action)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Action", "BaseNode")
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

    for _, p in ipairs(properties) do
        local methodStr = p["Method"]
        local resultOptionStr = p["ResultOption"]
        local resultFunctorStr = p["ResultFunctor"]

        if nil ~= methodStr then
            self.m_method = NodeParser.parseMethod(methodStr)
        elseif nil ~= resultOptionStr then
            if resultOptionStr == "BT_INVALID" then
                self.m_resultOption = EBTStatus.BT_INVALID
            elseif resultOptionStr == "BT_FAILURE" then
                self.m_resultOption = EBTStatus.BT_FAILURE
            elseif resultOptionStr == "BT_RUNNING" then
                self.m_resultOption = EBTStatus.BT_RUNNING
            else
                self.m_resultOption = EBTStatus.BT_SUCCESS
            end
        elseif nil ~= resultFunctorStr then
            self.m_resultFunctor = NodeParser.parseMethod(resultFunctorStr)
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
        self.m_method:run(agent)
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
            self.m_method:run(agent)
            status = self.m_resultOption
        else
            local val = nil
            if self.m_resultFunctor then
                val = self.m_resultFunctor:getValueFrom(agent, self.m_method)
            else
                val = self.m_method:getValue(agent)
            end
            status = val and tonumber(val) or EBTStatus.BT_FAILURE
        end
    else
        status = self:evaluateImpl(agent, tick, childStatus)
    end
    return status
end

return _M