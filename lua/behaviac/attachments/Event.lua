--- Behaviac lib Component: event attachements node.
-- @module Event.lua
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
local Condition = require(pdir .. "core.Condition")
local Event = class("Event", Condition)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Event", Event)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Event", "Condition")
local _M = Event

local NodeParser = require(pdir .. "parser.NodeParser")
local BehaviorTreeFactory = require(pdir .. "Parser.BehaviorTreeFactory")

local AgentMeta = require(pdir .. "agent.AgentMeta")

--------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_event               = false
    self.m_eventName           = ""
    self.m_triggerMode         = TriggerMode.TM_Transfer
    self.m_bTriggeredOnce      = false
    self.m_referencedTreeName  = ""
    self.m_referencedTreePath  = ""
end

function _M:release()
    _M.super.release()
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "Task" then
            self.m_event, self.m_eventName = NodeParser.parseMethodOutMethodName(valueStr)
        elseif nameStr == "ReferenceFilename" then
            self.m_referencedTreeName = valueStr
            self.m_referencedTreePath = AgentMeta.getBehaviorTreePath(self.m_referencedTreeName)
            local bt = BehaviorTreeFactory.preloadBehaviorTree(self.m_referencedTreePath)
        elseif nameStr == "TriggeredOnce" then
            if valueStr == "true" then
                self.m_bTriggeredOnce = true
            end
        elseif nameStr == "TriggerMode" then
            if valueStr == "Transfer" then
                self.m_triggerMode = TriggerMode.TM_Transfer
            elseif valueStr == "Return" then
                self.m_triggerMode = TriggerMode.TM_Return
            else
                _G.BEHAVIAC_ASSERT(false, "unrecognised trigger mode %s", valueStr)
            end
        else
            -- _G.BEHAVIAC_ASSERT(0, "unrecognized property")
        end
    end
end

function _M:getEventName()
    return self.m_eventName
end

function _M:triggeredOnce()
    return self.m_bTriggeredOnce
end

function _M:getTriggerMode()
    return self.m_triggerMode
end

function _M:referencedTreePath()
    return m_referencedTreePath
end

function _M:switchTo(agent, tick, eventParams)
    if not StringUtils.isNullOrEmpty(self.m_referencedTreePath) then
        if agent then
            local tm = self:getTriggerMode()
            agent:btEventTree(self.m_referencedTreePath, tm)
            agent.m_blackboard:addLocalVariables(eventParams)
            agent:btExec()
        end
    end
end

function _M:isEvent()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)
end

function _M:onEnter(agent, tick)
    return true
end

function _M:onExit(agent, tick, status)
    return true
end

function _M:traverse(childFirst, handler, agent, userData)
    handler(self, agent, userData)
end

function _M:update(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(self:isEvent(), "[_M:update()] self:isEvent()")

    if agent then
        local referencedTreePath = self:getReferencedTreePath()
        local triggerMode = self:getTriggerMode()
        if referencedTreePath and triggerMode then
            agent:btEventTree(referencedTreePath, triggerMode)
            agent:btexec()
        end
    end

    return EBTStatus.BT_SUCCESS
end

return _M