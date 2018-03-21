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
local BaseNode = require(ppdir .. "core.BaseNode")
local ReferencedBehavior = class("ReferencedBehavior", BaseNode)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("ReferencedBehavior", ReferencedBehavior)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("ReferencedBehavior", "BaseNode")
local _M = ReferencedBehavior

local NodeParser = require(ppdir .. "parser.NodeParser")
local BehaviorTreeFactory = require(ppdir .. "parser.BehaviorTreeFactory")

local AgentMeta = require(ppdir .. "agent.AgentMeta")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_referencedBehavior  = false
    self.m_referencedTreePath  = ""

    self.m_task                = false
    self.m_transitions         = false
    self.m_taskNode            = false
end

function _M:release()
    _M.super.release(self)

    self.m_referencedBehavior  = false
    self.m_task                = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    for _, p in ipairs(properties) do
        -- Note: property name is "ReferenceBehavior", not "ReferencedBehavior"
        --       "ReferencedBehavior" is class name
        local referencedBehaviorStr = p["ReferenceBehavior"]
        local taskStr = p["Task"]

        if nil ~= referencedBehaviorStr then
            if StringUtils.isValidString(referencedBehaviorStr) then
                local pParenthesis = string.find(referencedBehaviorStr, '%(')
                if not pParenthesis then
                    self.m_referencedBehavior = NodeParser.parseProperty(referencedBehaviorStr)
                else
                    self.m_referencedBehavior = NodeParser.parseMethod(referencedBehaviorStr)
                end

                self.m_referencedTreePath = self:getReferencedTree()

                -- conservatively make it true
                local bHasEvents = true

                if not StringUtils.isNullOrEmpty(self.m_referencedTreePath) then
                    local bt = BehaviorTreeFactory.preloadBehaviorTree(self.m_referencedTreePath)

                    _G.BEHAVIAC_ASSERT(behaviorTree, "")
                    if behaviorTree then
                        bHasEvents = behaviorTree:hasEvents()
                    end

                    self.m_bHasEvents = self.m_bHasEvents or bHasEvents
                end
            end
        elseif nil ~= taskStr then
            _G.BEHAVIAC_ASSERT(not StringUtils.isNullOrEmpty(taskStr))
            self.m_task = NodeParser.parseMethod(taskStr)
        else
            -- _G.BEHAVIAC_ASSERT(0, "unrecognized property")
        end
    end
end

function _M:setTaskParams(agent, treeTask)
    if self.m_task then
        self.m_task:setTaskParams(agent, treeTask)
    end
end

--See: referencebehavior.cpp
--     Task* ReferencedBehavior::RootTaskNode(Agent* pAgent)
function _M:rootTaskNode(agent)
    if not self.m_taskNode then
        local bt = BehaviorTreeFactory.preloadBehaviorTree(self.m_referencedTreePath)

        if bt and bt:getChildrenCount() == 1 then
            self.m_taskNode = bt:getChild(1)
        end
    end

    return self.m_taskNode
end

function _M:getReferencedTree()
    _G.BEHAVIAC_ASSERT(self.m_referencedBehavior, "[_M:getReferencedTree()] m_referencedBehavior")
    local treeName = self.m_referencedBehavior:getValue(agent)
    treeName = StringUtils.trimEnclosedDoubleQuotes(treeName)
    return AgentMeta.getBehaviorTreePath(treeName)
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
    local szTreePath = self:getReferencedTree(tick)
    
    -- to create the task on demand
    local subTreeTick = self:getSubTreeTick(tick)
    if szTreePath and (not subTreeTick or StringUtils.compare(szTreePath, subTreeTick:getRelativePath(), true)) then
        subTreeTick = agent:btCreateTreeTick(szTreePath)
        self:setSubTreeTick(tick, subTreeTick)
        self:setTaskParams(tick, subTreeTick)
    elseif subTreeTick then
        local pSubBt = subTreeTick:getBt()
        subTreeTick:reset(pSubBt, agent)
    end
    return true
end

function _M:onExit(agent, tick, status)
end

function _M:update(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(self:isReferencedBehavior(), "[_M:update()] self:isReferencedBehavior")
    local status = self.m_subTreeTick:exec(self, agent)
    local bTransitioned, nextStateId = State.s_updateTransitions(self, agent, tick, self.m_transitions, self.m_nextStateId, status)
    self.m_nextStateId = nextStateId

    if bTransitioned then
        if status == EBTStatus.BT_RUNNING then
            -- subtree not exited, but it will transition to other states
            self.m_subTreeTick:abort(agent)
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