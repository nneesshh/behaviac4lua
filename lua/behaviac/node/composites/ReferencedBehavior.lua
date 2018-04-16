--- Behaviac lib Component: referenced behavior composite node.
-- @module ReferencedBehavior.lua
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
local SingleChild = require(ppdir .. "core.SingleChild")
local ReferencedBehavior = class("ReferencedBehavior", SingleChild)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("ReferencedBehavior", ReferencedBehavior)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("ReferencedBehavior", "SingleChild")
local _M = ReferencedBehavior

local NodeParser = require(ppdir .. "parser.NodeParser")
local BehaviorTreeFactory = require(ppdir .. "parser.BehaviorTreeFactory")

local AgentMeta = require(ppdir .. "agent.AgentMeta")
local State = require(ppdir .. "fsm.State")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_referenced_behavior_p  = false
    self.m_referencedTreePath     = false
    self.m_bHasEvents             = false

    self.m_taskPrototype          = false
    self.m_transitions            = false
    self.m_taskPrototypeNode      = false
end

function _M:release()
    _M.super.release(self)

    self.m_referenced_behavior_p  = false
    self.m_taskPrototype          = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        -- Note: property name is "ReferenceBehavior", not "ReferencedBehavior"
        --       "ReferencedBehavior" is class name
        if nameStr == "ReferenceBehavior" then
            if StringUtils.isValidString(valueStr) then
                local pParenthesis = string.find(valueStr, '%(')
                if not pParenthesis then
                    self.m_referenced_behavior_p = NodeParser.parseProperty(valueStr)
                else
                    self.m_referenced_behavior_p = NodeParser.parseMethod(valueStr)
                end
            end
        elseif nameStr == "Task" then
            _G.BEHAVIAC_ASSERT(not StringUtils.isNullOrEmpty(valueStr))
            self.m_taskPrototype = NodeParser.parseTaskPrototype(valueStr)
        else
            -- _G.BEHAVIAC_ASSERT(0, "unrecognized property")
        end
    end
end

function _M:setTaskParams(agent, tick, subTreeTick)
    if self.m_taskPrototype then
        self.m_taskPrototype:setTaskParams(agent, tick, subTreeTick)
    end
end

function _M:getReferencedTreePath(agent, tick)
    _G.BEHAVIAC_ASSERT(self.m_referenced_behavior_p, "[_M:getReferencedTreePath()] m_referenced_behavior_p")

    if not self.m_referencedTreePath then
        local name = self.m_referenced_behavior_p:getValue(agent, tick)
        local _, name2 = StringUtils.trimEnclosedDoubleQuotes(name)
        self.m_referencedTreePath = AgentMeta.getBehaviorTreePath(name2)

        -- conservatively make it true
        local bHasEvents = true

        if not StringUtils.isNullOrEmpty(self.m_referencedTreePath) then
            local refBt = BehaviorTreeFactory.preloadBehaviorTree(self.m_referencedTreePath)

            _G.BEHAVIAC_ASSERT(refBt)
            if refBt then
                bHasEvents = refBt:hasEvents()
            end

            self.m_bHasEvents = self.m_bHasEvents or bHasEvents
        end
    end
    return self.m_referencedTreePath
 end

function _M:attach(pAttachment, isPrecondition, isEffector, isTransition)
    if isTransition then
        _G.BEHAVIAC_ASSERT(not isEffector and not isPrecondition, "[_M:attach()] not isEffector and not isPrecondition")
        
        if not self.m_transitions then
            self.m_transitions = {}
        end

        _G.BEHAVIAC_ASSERT(pAttachment:isTransition(), "[_M:attach()] pAttachment:isTransition")
        table.insert(self.m_transitions, pAttachment)
        return
    end

    _G.BEHAVIAC_ASSERT(not isTransition, "[_M:attach()] isTransition")
    _M.super.attach(self, pAttachment, isPrecondition, isEffector, isTransition)
end

function _M:isReferencedBehavior()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    self:setNextStateId(tick, -1)
    self:setSubTreeTick(tick, false)
end

function _M:onEvent(agent, tick, eventName, eventParams)
    local status = self:getStatus(tick)
    if status == EBTStatus.BT_RUNNING and self:hasEvents() then
        local subTreeTick = self:getSubTreeTick(tick)
        _G.BEHAVIAC_ASSERT(subTreeTick, "[_M:onEvent()] subTreeTick")

        if not subTreeTick:onEvent(agent, subTreeTick, eventName, eventParams) then
            return false
        end
    end

    return true
end

function _M:onEnter(agent, tick)
    _G.BEHAVIAC_ASSERT(self:isReferencedBehavior(), "[_M:onEnter()] self:isReferencedBehavior")
    self:setNextStateId(tick, -1)
    local szTreePath = self:getReferencedTreePath(agent, tick)
    
    -- to create the task on demand
    local subTreeTick = self:getSubTreeTick(tick)
    local pSubBt = subTreeTick and subTreeTick:getBt()
    if szTreePath and (not pSubBt or not StringUtils.compare(szTreePath, pSubBt:getRelativePath(), true)) then
        subTreeTick = agent:btCreateTreeTick(szTreePath)
        self:setSubTreeTick(tick, subTreeTick)
    elseif subTreeTick then
        subTreeTick:reset(pSubBt, agent)
    end
    self:setTaskParams(agent, tick, subTreeTick)
    return true
end

function _M:onExit(agent, tick, status)
end

function _M:update(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(self:isReferencedBehavior(), "[_M:update()] self:isReferencedBehavior")
    local subTreeTick = self:getSubTreeTick(tick)
    local status = subTreeTick:exec(subTreeTick:getBt(), agent)
    local bTransitioned, nextStateId = State.s_updateTransitions(self, agent, tick, self.m_transitions, self.m_nextStateId, status)
    self.m_nextStateId = nextStateId

    if bTransitioned then
        if status == EBTStatus.BT_RUNNING then
            -- subtree not exited, but it will transition to other states
            subTreeTick:abort(agent)
        end

        status = EBTStatus.BT_SUCCESS
    end

    return status
end

function _M:setNextStateId(tick, id)
    tick:setNodeMem("nextStateId", id, self)
end

function _M:getNextStateId(tick)
    return tick:getNodeMem("nextStateId", self)
end

function _M:setSubTreeTick(tick, subTree)
    tick:setNodeMem("subTreeTick", subTree, self)
end

function _M:getSubTreeTick(tick)
    return tick:getNodeMem("subTreeTick", self)
end

return _M