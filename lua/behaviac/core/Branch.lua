--- Behaviac lib Component: branch node.
-- @module Branch.lua
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
local BaseNode = require(cwd .. "BaseNode")
local Branch = class("Branch", BaseNode)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Branch", Branch)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Branch", "BaseNode")
local _M = Branch

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

function _M:isBranch()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)

    -- bookmark the current ticking node, it is different from m_activeChildIndex
    self:setCurrentVisitingNode(tick, false)
end

function _M:onEvent(agent, tick, eventName, eventParams)
    if self:hasEvents() then
        local bGoOn = true

        local curVisitingNode = self:getCurrentVisitingNode(tick)
        if curVisitingNode then
            bGoOn = self:onEventCurrentVisitingNode(agent, tick, eventName, eventParams)
        end

        if bGoOn then
            bGoOn = _M.super.onEvent(self, agent, tick, eventName, eventParams)
        end
    end

    return true
end

function _M:onEnter(agent, tick)
    return true
end

function _M:onExit(agent, tick)
    -- do nothing
end

function _M:onEventCurrentVisitingNode(agent, tick, eventName, eventParams)
    local curVisitingNode = self:getCurrentVisitingNode(tick)
    if curVisitingNode then
        local s = curVisitingNode:getStatus(tick)
        _G.BEHAVIAC_ASSERT(s == EBTStatus.BT_RUNNING and self:hasEvents(), "[_M:onEventCurrentVisitingNode()] invalid status=%d", s)

        local bGoOn = curVisitingNode:onEvent(agent, tick, eventName, eventParams)
        
        -- give the handling back to parents
        if bGoOn and curVisitingNode then
            parentBranch = curVisitingNode:getParent()

            -- back track the parents until the branch
            while parentBranch and parentBranch ~= self do
                _G.BEHAVIAC_ASSERT(parentBranch:getStatus(tick) == EBTStatus.BT_RUNNING, "[_M:onEventCurrentVisitingNode()] invalid status=%d", parentBranch:getStatus(tick))

                bGoOn = parentBranch:onEvent(agent, tick, eventName, eventParams)
                if not bGoOn then
                    return false
                end

                parentBranch = parentBranch:getParent()
            end
        end

        return bGoOn
    end

    return true
end

function _M:updateCurrent(agent, tick, childStatus)
    local status = EBTStatus.BT_INVALID
    local curVisitingNode = self:getCurrentVisitingNode(tick)
    if curVisitingNode then
        return self:execCurrentVisitingNode(curVisitingNode, agent, tick, childStatus)
    else
        return self:update(agent, tick, childStatus)
    end
end

function _M:execCurrentVisitingNode(curVisitingNode, agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(curVisitingNode)
    if curVisitingNode:getStatus(tick) ~= EBTStatus.BT_RUNNING then
        Logging.error("[_M:execCurrentVisitingNode()] selfNode(%d)curVisitingNode(%d) status (%d) is not running", self:getId(), curVisitingNode:getId(), curVisitingNode:getStatus(tick))
        return EBTStatus.BT_FAILURE
    end

    local status = tick:execWithChildStatus(curVisitingNode, agent, childStatus)
    
    -- give the handling back to parents if out of running
    if status ~= EBTStatus.BT_RUNNING then
        -- state must BT_SUCCESS orBT_FAILURE
        _G.BEHAVIAC_ASSERT(status == EBTStatus.BT_SUCCESS or status == EBTStatus.BT_FAILURE)
        _G.BEHAVIAC_ASSERT(curVisitingNode:getStatus(tick) == status)

        local parentBranch = curVisitingNode:getParent()
        self:setCurrentVisitingNode(tick, false)

        -- back track the parents until the branch
        while parentBranch do
            if parentBranch == self then
                status = parentBranch:update(agent, tick, status)
            else
                status = parentBranch:execWithChildStatus(agent, tick, status)
            end

            if status == EBTStatus.BT_RUNNING then
                return EBTStatus.BT_RUNNING
            end

            local parentBranchStatus = parentBranch:getStatus(tick)
            _G.BEHAVIAC_ASSERT(parentBranch == self or parentBranchStatus == status)

            if parentBranch == self then
                break
            end

            parentBranch = parentBranch:getParent()
        end
    end

    return status
end

function _M:resumeBranch(agent, tick, status)
    local curVisitingNode = self:getCurrentVisitingNode(tick)
    if not curVisitingNode then
        Logging.error("[_M:resumeBranch()] no current visiting node")
        return EBTStatus.BT_INVALID
    end

    if not(status == EBTStatus.BT_SUCCESS or status == EBTStatus.BT_FAILURE) then
        Logging.error("[_M:resumeBranch()] error status %", status)
        return EBTStatus.BT_INVALID
    end

    local parent = false
    local _tNode = curVisitingNode
    if _tNode:isManagingChildrenAsSubTrees() then
        parent = curVisitingNode
    else
        parent = curVisitingNode:getParent()
    end

    -- clear it as it ends and the next exec might need to set it
    self:setCurrentVisitingNode(tick, false)
    return parent:execWithChildStatus(agent, status)
end

-- See behaviortree_task.cpp
--     void BranchTask::SetCurrentTask(BehaviorTask* task)
function _M:markVisiting(tick, visitingNode)
    local pLastVisitingNode = self:getCurrentVisitingNode(tick)
    if visitingNode then
        -- if the leaf node is running, then the leaf's parent node is also as running,
        -- the leaf is set as the tree's current task instead of its parent
        if not pLastVisitingNode then
            _M.setCurrentVisitingNode(self, tick, visitingNode)

            -- print("node", visitingNode.__name)
            visitingNode:setHasManagingParent(tick, true)
        end
    else
        local status = self:getStatus(tick)
        if status ~= EBTStatus.BT_RUNNING then
            _M.setCurrentVisitingNode(self, tick, visitingNode)
        end
    end
end

function _M:setCurrentVisitingNode(tick, visitingNode)
    tick:setNodeMem("currentVisitingNode", visitingNode, self)
end

function _M:getCurrentVisitingNode(tick)
    return tick:getNodeMem("currentVisitingNode", self)
end

return _M