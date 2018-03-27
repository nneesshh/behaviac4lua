--- Behaviac lib Component: base node.
-- @module BaseNode.lua
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
local BaseNode = class("BaseNode")
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("BaseNode", BaseNode)
local _M = BaseNode

--------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    self.m_nodeClassName         = ""
    self.m_id                    = 0        
    self.m_agentType             = ""

    self.m_bHasEvents            = false
    self.m_children              = false
    self.m_preconditions         = {}
    self.m_effectors             = {}
    self.m_events                = {}
    self.m_customCondition       = false
    self.m_parent                = false
    self.m_loadAttachment        = false -- indicates loading or not
    self.m_enterPrecond          = 0
    self.m_updatePrecond         = 0
    self.m_bothPrecond           = 0
    self.m_successEffectors      = 0
    self.m_failureEffectors      = 0
    self.m_bothEffectors         = 0

    self.m_localProps            = {}
    self.m_loaderCallback        = function() end
    self.m_nodeFactory           = require(pdir .. "parser.NodeFactory")
end

-- release
function _M:release()
    self:clear()
end

function _M:clear()
    if self.m_children then
        for _, child in ipairs(self.m_children) do
            child:release()
        end
        self.m_children = false
    end

    if self.m_customCondition then
        self.m_customCondition:release()
        self.m_customCondition = false
    end
end

-- Process node loaded event
-- this is called for every behavior node, in which users can do some custom stuff
-- See: behaviortree.cpp
--      void BehaviorNode::load(int version, const char* agentType, const properties_t& properties)
function _M:onLoading(version, agentType, properties)
    self:m_loaderCallback(version, agentType, properties)
end

function _M:attach(attachmentNode, isPrecondition, isEffector, isTransition)
    _G.BEHAVIAC_ASSERT(isTransition == false, "isTransition must be false") -- TODO: 为什么？

    if isPrecondition then
        _G.BEHAVIAC_ASSERT(not isEffector)
        _G.BEHAVIAC_ASSERT(attachmentNode)  -- TODO: 检测是否是附件
        table.insert(self.m_preconditions, attachmentNode)

        local phase = attachmentNode:getPhase()
        if phase == EPreconditionPhase.E_ENTER then
            self.m_enterPrecond = self.m_enterPrecond + 1
        elseif phase == EPreconditionPhase.E_UPDATE then
            self.m_updatePrecond = self.m_updatePrecond + 1
        elseif phase == EPreconditionPhase.E_BOTH then
            self.m_bothPrecond = self.m_bothPrecond + 1
        else
            _G.BEHAVIAC_ASSERT(false, "[_M:attach()] isPrecondition error EPreconditionPhase = %d", phase)
        end
    elseif isEffector then
        _G.BEHAVIAC_ASSERT(not isPrecondition)
        _G.BEHAVIAC_ASSERT(attachmentNode)  -- TODO: 检测是否是Effector
        table.insert(self.m_effectors, attachmentNode)

        local phase = attachmentNode:getPhase()
        if phase == ENodePhase.E_SUCCESS then
            self.m_successEffectors = self.m_successEffectors + 1
        elseif phase == ENodePhase.E_FAILURE then
            self.m_failureEffectors = self.m_failureEffectors + 1
        elseif phase == ENodePhase.E_BOTH then
            self.m_bothEffectors = self.m_bothEffectors + 1
        else
            _G.BEHAVIAC_ASSERT(false, "[_M:attach()] isEffector error ENodePhase = %d", phase)
        end
    else
        table.insert(self.m_events, attachmentNode)
    end
end

function _M:combineResults(firstValidPrecond, lastCombineValue, precond, taskBoolean)
    if firstValidPrecond then
        firstValidPrecond = false
        lastCombineValue = taskBoolean
    else
        local andOp = precond:isAnd()
        if andOp then
            lastCombineValue = lastCombineValue and taskBoolean
        else
            lastCombineValue = lastCombineValue or taskBoolean
        end
    end

    return firstValidPrecond, lastCombineValue
end

function _M:hasEvents()
    return self.m_bHasEvents
end

function _M:setEvents(hasEvents)
    self.m_bHasEvents = hasEvents
end

function _M:setClassNameString(nodeClassName)
    self.m_nodeClassName = nodeClassName
end

function _M:getClassNameString()
    return self.m_nodeClassName
end

function _M:setId(id)
    self.m_id = id
end

function _M:getId()
    return self.m_id
end

function _M:setAgentType(agentType)
    self.m_agentType = agentType
end

function _M:getAgentType()
    return self.m_agentType
end

function _M:setParent(parentNode)
    self.m_parent = parentNode
end

function _M:getParent()
    return self.m_parent
end

function _M:getRoot()
    local node = self
    while node.m_parent do
        node = node.m_parent
    end

    _G.BEHAVIAC_ASSERT(task.isBehaviorTree(), "[_M:getParent()] root must be BehaviorTree!!!")
    return node
end

--
-- Children
--
function _M:getChildrenCount()
    if self.m_children then
        return #self.m_children
    else
        return 0
    end
end

function _M:addChild(childNode)
    childNode.m_parent = self
    if not self.m_children then
        self.m_children = {}
    end
    table.insert(self.m_children, childNode)
end

function _M:getChild(index)
    if self.m_children then
        return self.m_children[index]
    else
        return false
    end
end

function _M:getChildById(nodeId)
    if not self.m_children then
        return false
    end

    for _, child in ipairs(self.m_children) do
        if child:getId() == nodeId then
            return child
        end
    end

    return false
end

function _M:setCustomCondition(node)
    self.m_customCondition = node
end

function _M:loadLocal(version, agentType, dataEntry)
    -- Do nothing in base node
end

-- return true for Parallel, SelectorLoop, etc., which is responsible to update all its children just like sub trees
-- so that they are treated as a return-running node and the next update will continue them.
function _M:isManagingChildrenAsSubTrees()
    return false
end

function _M:isBehaviorTree()
    return false
end

function _M:isBranch()
    return false
end

function _M:isEvent()
    return false
end

function _M:isAnd()
    return false
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)

    self:setStatus(tick, EBTStatus.BT_INVALID)
    self:setHasManagingParent(tick, false)
end

function _M:onReset(agent, tick)
    
end

function _M:onEnter(agent, tick)
    return true
end

-- return false if the event handling  needs to be stopped
-- return true, the event hanlding will be checked furtherly
function _M:onEvent(agent, tick, eventName, eventParams)
    local status = self:getStatus(tick)
    if status == EBTStatus.BT_RUNNING and self:hasEvents() then
        if not self:checkEvents(agent, tick, eventName, eventParams) then
            return false
        end
    end

    return true
end

function _M:applyEffects(agent, tick, phase)
    if #self.m_effectors == 0 then
        return
    end

    if self.m_bothEffectors == 0 then
        if phase == ENodePhase.E_SUCCESS and self.m_successEffectors == 0 then
            return
        end

        if phase == ENodePhase.E_FAILURE and self.m_failureEffectors == 0 then
            return
        end
    end

    for _, effector in ipairs(self.m_effectors) do
        local ph = effector:getPhase()
        if phase == ENodePhase.E_BOTH or ph == ENodePhase.E_BOTH or ph == phase then
            effector:evaluate(agent, tick)
        end
    end
end

--
function _M:checkPreconditions(agent, tick, isAlive)
    local phase = isAlive and EPreconditionPhase.E_UPDATE or EPreconditionPhase.E_ENTER

    -- satisfied if there is no preconditions
    if #self.m_preconditions == 0 then
        return true
    end

    if self.m_bothPrecond == 0 then
        if phase == EPreconditionPhase.E_ENTER and self.m_enterPrecond == 0 then
            return true
        end

        if phase == EPreconditionPhase.E_UPDATE and self.m_updatePrecond == 0 then
            return true
        end
    end

    local firstValidPrecond = true
    local lastCombineValue  = false

    for _, precond in ipairs(self.m_preconditions) do
        local ph = precond:getPhase()
        if ph == EPreconditionPhase.E_BOTH or ph == phase then
            local taskBoolean = precond:evaluate(agent, tick)

            firstValidPrecond, lastCombineValue = self:combineResults(firstValidPrecond, lastCombineValue, precond, taskBoolean)
        end
    end

    return lastCombineValue
end

-- Events
function _M:checkEvents(agent, tick, eventName, eventParams)
    if #self.m_events > 0 then
        for _, event in ipairs(self.m_events) do
            if event:isEvent() and not StringUtils.isNullOrEmpty(eventName) then
                local en = event:getEventName()
                if not StringUtils.isNullOrEmpty(en) and en == eventName then
                    event:switchTo(agent, tick, eventParams)
                    if event:triggeredOnce() then
                        return false
                    end
                end
            end
        end
    end

    return true
end

function _M:updateCurrent(agent, tick, childStatus)
    return self:update(agent, tick, childStatus)
end

function _M:update(agent, tick, childStatus)
    return EBTStatus.BT_SUCCESS
end

function _M:evaluate(agent, tick)
    Logging.error("[_M:evaluate()] must be inheritance, Only Condition/Sequence/And/Or allowed")
    return false
end

function _M:evaluteCustomCondition(agent, tick)
    if self.m_customCondition then
        return self.m_customCondition:evaluate(agent, tick)
    end

    return false
end

function _M:evaluateImpl(agent, tick, childrentatus)
    return EBTStatus.BT_FAILURE
end

function _M:setStatus(tick, status)
    tick:setNodeMem("status", status, self)
end

function _M:getStatus(tick)
    return tick:getNodeMem("status", self)
end

function _M:setHasManagingParent(tick, bHasManagingParent)
    tick:setNodeMem("hasManagingParent", bHasManagingParent, self)
end

function _M:getHasManagingParent(tick)
    return tick:getNodeMem("hasManagingParent", self)
end

function _M:setCurrentVisitingNode(tick, visitingNode)
    -- do nothing except branch
end

function _M:getCurrentVisitingNode(tick)
    -- do nothing except branch
end

return _M