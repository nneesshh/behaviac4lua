--- Behaviac lib Component: tick.
-- @module Tick.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {}

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
local Tick = class("Tick")
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Tick", Tick)
local _M = Tick

local Blackboard = require(cwd .. "Blackboard")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor(bt, blackboard)
    self.m_bt          = bt
    self.m_blackboard  = blackboard

    self.m_tickMem     = blackboard:getTreeMemory(self)
    self.m_localVars   = {}
end

function _M:init()
    self.m_bt:init(self)
end

--
function _M:exec(targetNode, agent)
    local childStatus = EBTStatus.BT_RUNNING
    return self:execWithChildStatus(targetNode, agent, childStatus)
end

-- See behaviortree_task.cpp
--     EBTStatus exec(Agent* pAgent, EBTStatus childStatus)
function _M:execWithChildStatus(targetNode, agent, childStatus)
    local status = targetNode:getStatus(self)
    
    local bEnterResult = false
    if status == EBTStatus.BT_RUNNING then
        bEnterResult = true
    else
        status = EBTStatus.BT_INVALID
        bEnterResult = self:onEnterAction(targetNode, agent)
    end

    if bEnterResult then
        local bValid = self:checkParentUpdatePreconditions(targetNode, agent)
        if bValid then
            status = targetNode:updateCurrent(agent, self, childStatus)
        else
            status = EBTStatus.BT_FAILURE
            if targetNode:getCurrentVisitingNode(self) then
                targetNode:updateCurrent(agent, self, EBTStatus.BT_FAILURE)
            end
        end

        if status ~= EBTStatus.BT_RUNNING then
            -- clear it
            self:onExitAction(targetNode, agent, status)
            -- this node is possibly ticked by its parent or by the topBranch who records it as currrent node so, we can't here reset the topBranch's current nod
        else
            local tree = self:getTopManageBranchNode(targetNode)
            if tree then
                tree:markVisiting(self, targetNode)
            end
        end
    else
        status = EBTStatus.BT_FAILURE
    end
    
    targetNode:setStatus(self, status)
    return status
end

--
function _M:checkParentUpdatePreconditions(targetNode, agent)
    local bValid = true
    local bHasManagingParent = targetNode:getHasManagingParent(self)
    if bHasManagingParent then
        local bHasManagingParent    = false
        local kMaxParentsCount      = 512
        local parentsCount          = 0

        local parents = {}
        local parentBranch = targetNode:getParent()
        table.insert(parents, targetNode)        
        
        while parentBranch do
            if #parents >= kMaxParentsCount then
                Logging.error("[_M:checkParentUpdatePreconditions()] weird tree!")
                break
            end

            table.insert(parents, parentBranch)
            if parentBranch:getCurrentVisitingNode(self) == targetNode then
                bHasManagingParent = true
                break
            end
            parentBranch = parentBranch:getParent()
        end

        if bHasManagingParent then
            for k = #parents, 1, -1 do
                bValid = parents[k]:checkPreconditions(agent, self, true)
                if not bValid then
                    break
                end
            end
        end
    else
        bValid = targetNode:checkPreconditions(agent, self, true)
    end

    return bValid
end

-- Get the Root of branch node
function _M:getTopManageBranchNode(targetNode)
    local node = nil
    local parent = targetNode.m_parent

    while parent do
        if parent:isBehaviorTree() then
            -- to overwrite the child branch
            node = parent
            break
        elseif parent and parent:isManagingChildrenAsSubTrees() then
            -- until it is Parallel/SelectorLoop, it's child is used as tree to store current parent
            break
        elseif parent:isBranch() then
            node = parent
        else
            _G.BEHAVIAC_ASSERT(false, "[_M:getTopManageBranchNode()]")
        end
        parent = parent.m_parent
    end

    return node
end

function _M:onEnterAction(targetNode, agent)
    local bResult = targetNode:checkPreconditions(agent, self, false)
    if bResult then
        targetNode:setHasManagingParent(self, false)
        targetNode:setCurrentVisitingNode(self, false)
        bResult = targetNode:onEnter(agent, self)
        if not bResult then
            return false
        else
            -- do nothing
        end
    end

    return bResult
end

function _M:onExitAction(targetNode, agent, status)
    targetNode:onExit(agent, self, status)

    local phase = ENodePhase.E_SUCCESS

    if status == EBTStatus.BT_FAILURE then
        phase = ENodePhase.E_FAILURE
    else
        _G.BEHAVIAC_ASSERT(status == EBTStatus.BT_SUCCESS, string.format("[onExitAction] status (%d) must be EBTStatus.BT_SUCCESS", status))
    end
    targetNode:applyEffects(agent, self, phase)
end

local function _getRunningNodesHandler(node, agent, tick, retNodes)
    local status = node:getStatus(tick)
    if status == EBTStatus.BT_RUNNING then
        table.insert(retNodes, node)
    end

    return true
end

function _M:getRunningNodes(targetNode, onlyLeaves)
    if onlyLeaves == nil then
        onlyLeaves = true
    end

    local nodes = {}
    targetNode:traverse(true, _getRunningNodesHandler, nil, self, nodes)
    if onlyLeaves and #nodes > 0 then
        local leaves = {}
        for _, one in ipairs(nodes) do
            if one:isLeaf() then
                table.insert(leaves, one)
            end
        end
        return leaves
    end

    return nodes
end

local function _abortHandler(node, agent, tick, userData)
    --_G.BEHAVIAC_UNUSED_VAR(userData)
    local status = node:getStatus(tick)
    if status == EBTStatus.BT_RUNNING then
        tick:onExitAction(node, agent, EBTStatus.BT_FAILURE)
        node:setStatus(tick, EBTStatus.BT_FAILURE)
        node:setCurrentVisitingNode(tick, false)
    end

    return true
end

function _M:abort(targetNode, agent)
    targetNode:traverse(true, _abortHandler, agent, self, nil)
end

local function _resetHandler(node, agent, tick, userData)
    --_G.BEHAVIAC_UNUSED_VAR(userData)
    node:setStatus(tick, EBTStatus.BT_INVALID)
    node:setCurrentVisitingNode(tick, false)
    node:onReset(agent, tick)
    return true
end

function _M:reset(targetNode, agent)
    targetNode:traverse(true, _resetHandler, agent, self, nil)
end

local function _endHandler(node, agent, tick, userData)
    local status = node:getStatus(tick)
    if status == EBTStatus.BT_RUNNING or status == EBTStatus.BT_INVALID  then
        tick:onExitAction(node, agent, userData)
        node:setStatus(tick, userData)
        node:setLastRunningNode(tick, false)
    end

    return true
end

function _M:endDo(targetNode, agent, status)
    targetNode:traverse(true, _endHandler, agent, self, status)
end

function _M:getBt()
    return self.m_bt
end

function _M:setMem(key, value)
    self.m_tickMem[key] = value
end

function _M:getMem(key)
    return self.m_tickMem[key]
end

function _M:setNodeMem(key, value, node)
    Blackboard.s_setTreeNode(self.m_tickMem, key, value, node)
end

function _M:getNodeMem(key, node)
    return Blackboard.s_getTreeNode(self.m_tickMem, key, node)
end

function _M:setLocalVariable(varName, var) 
    self.m_localVars[varName] = var
end

function _M:addLocalVariables(vars)
    if #vars > 0 then
        local varName, var
         for _, v in ipairs(vars) do
            varName = v[1]
            var = v[2]
            self.m_localVars[varName] = var
         end
    end
end

function _M:getLocalVariable(varName)
    return self.m_localVars[varName]
end

return _M