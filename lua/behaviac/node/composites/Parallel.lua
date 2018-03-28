--- Behaviac lib Component: parallel composite node.
-- @module Parallel.lua
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
-- Execute behaviors in parallel
-- There are two policies that control the flow of execution:
-- the policy for failure, and the policy for success.
local Composite = require(ppdir .. "core.Composite")
local Parallel = class("Parallel", Composite)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Parallel", Parallel)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Parallel", "Composite")
local _M = Parallel

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- options when a parallel node is considered to be failed.
-- FAIL_ON_ONE: the node fails as soon as one of its children fails.
-- FAIL_ON_ALL: the node failes when all of the node's children must fail
-- If FAIL_ON_ONE and SUCEED_ON_ONE are both active and are both trigerred, it fails
EFAILURE_POLICY = {
    FAIL_ON_ONE = 0,
    FAIL_ON_ALL = 1,
}

-- options when a parallel node is considered to be succeeded.
-- SUCCEED_ON_ONE: the node will return success as soon as one of its children succeeds.
-- SUCCEED_ON_ALL: the node will return success when all the node's children must succeed.
ESUCCESS_POLICY = {
    SUCCEED_ON_ONE = 0,
    SUCCEED_ON_ALL = 1,
}

-- options when a parallel node is exited
-- EXIT_NONE: the parallel node just exit.
-- EXIT_ABORT_RUNNINGSIBLINGS: the parallel node abort all other running siblings.
EEXIT_POLICY = {
    EXIT_NONE = 0,
    EXIT_ABORT_RUNNINGSIBLINGS = 1
}

-- the options of what to do when a child finishes
-- CHILDFINISH_ONCE: the child node just executes once.
-- CHILDFINISH_LOOP: the child node runs again and again.
ECHILDFINISH_POLICY = {
    CHILDFINISH_ONCE = 0,
    CHILDFINISH_LOOP = 1
}

-- ctor
function _M:ctor()
    _M.super.ctor(self)
    
    self.m_failPolicy           = EFAILURE_POLICY.FAIL_ON_ONE
    self.m_succeedPolicy        = ESUCCESS_POLICY.SUCCEED_ON_ALL
    self.m_exitPolicy           = EEXIT_POLICY.EXIT_NONE
    self.m_childFinishPolicy    = ECHILDFINISH_POLICY.CHILDFINISH_LOOP
end

function _M:release()
    _M.super.release(self)
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "FailurePolicy" then
            if valueStr == "FAIL_ON_ONE" then
                self.m_failPolicy = EFAILURE_POLICY.FAIL_ON_ONE
            elseif valueStr == "FAIL_ON_ALL" then
                self.m_failPolicy = EFAILURE_POLICY.FAIL_ON_ALL
            else
                _G.BEHAVIAC_ASSERT(false, "[_M:onLoading()] FailurePolicy error value = %s", valueStr)
            end
        elseif nameStr == "SuccessPolicy" then
            if valueStr == "SUCCEED_ON_ONE" then
                self.m_succeedPolicy = ESUCCESS_POLICY.SUCCEED_ON_ONE
            elseif valueStr == "SUCCEED_ON_ALL" then
                self.m_succeedPolicy = ESUCCESS_POLICY.SUCCEED_ON_ALL
            else
                _G.BEHAVIAC_ASSERT(false, "[_M:onLoading()] SuccessPolicy error value = %s", valueStr)
            end
        elseif nameStr == "ExitPolicy" then
            if valueStr == "EXIT_NONE" then
                self.m_exitPolicy = EEXIT_POLICY.EXIT_NONE
            elseif valueStr == "EXIT_ABORT_RUNNINGSIBLINGS" then
                self.m_exitPolicy = EEXIT_POLICY.EXIT_ABORT_RUNNINGSIBLINGS
            else
                _G.BEHAVIAC_ASSERT(false, "[_M:onLoading()] ExitPolicy error value = %s", valueStr)
            end
        elseif nameStr == "ChildFinishPolicy" then
            if valueStr == "CHILDFINISH_ONCE" then
                self.m_childFinishPolicy = ECHILDFINISH_POLICY.CHILDFINISH_ONCE
            elseif valueStr == "CHILDFINISH_LOOP" then
                self.m_childFinishPolicy = ECHILDFINISH_POLICY.CHILDFINISH_LOOP
            else
                _G.BEHAVIAC_ASSERT(false, "[_M:onLoading()] ChildFinishPolicy error value = %s", valueStr)
            end
        else
            -- _G.BEHAVIAC_ASSERT(false)
        end
    end
end

function _M:parallelUpdate(agent, tick, children)
    local sawSuccess    = false
    local sawFail       = false
    local sawRunning    = false
    local sawAllFails   = true
    local sawAllSuccess = true

    local bLoop = (self.m_childFinishPolicy == ECHILDFINISH_POLICY.CHILDFINISH_LOOP)

    -- go through all m_children
    for _, pChild in ipairs(children) do
        local treeStatus = pChild:getStatus(tick)
        if bLoop or treeStatus == EBTStatus.BT_RUNNING or treeStatus == EBTStatus.BT_INVALID then
            local status = tick:exec(pChild, agent)
            if status == EBTStatus.BT_FAILURE then
                sawFail = true
                sawAllSuccess = false
            elseif status == EBTStatus.BT_SUCCESS then
                sawSuccess = true
                sawAllFails = false
            elseif status == EBTStatus.BT_RUNNING then
                sawRunning = true
                sawAllFails = false
                sawAllSuccess = false
            end
        elseif treeStatus == EBTStatus.BT_SUCCESS then
            sawSuccess = true
            sawAllFails = false
        else
            _G.BEHAVIAC_ASSERT(treeStatus == EBTStatus.BT_FAILURE)
            sawFail = true
            sawAllSuccess = false
        end
    end

    local status = sawRunning and EBTStatus.BT_RUNNING or EBTStatus.BT_FAILURE
    if (self.m_failPolicy == EFAILURE_POLICY.FAIL_ON_ALL and sawAllFails) or
       (self.m_failPolicy == EFAILURE_POLICY.FAIL_ON_ONE and sawFail) then
        status = EBTStatus.BT_FAILURE
    elseif (self.m_succeedPolicy == ESUCCESS_POLICY.SUCCEED_ON_ALL and sawAllSuccess) or
       (self.m_succeedPolicy == ESUCCESS_POLICY.SUCCEED_ON_ONE and sawSuccess) then
        status = EBTStatus.BT_SUCCESS
    end

    if self.m_exitPolicy == EEXIT_POLICY.EXIT_ABORT_RUNNINGSIBLINGS and (status == EBTStatus.BT_FAILURE or status == EBTStatus.BT_SUCCESS) then
        for _, pChild in ipairs(children) do
            local treeStatus = pChild:getStatus(tick)
            if treeStatus == EBTStatus.BT_RUNNING then
                pChild:abort(agent)
            end
        end
    end

    return status
end

function _M:isManagingChildrenAsSubTrees()
    return true
end

function _M:setPolicy(failPolicy, successPolicy, exitPolicty)
    if not failPolicy then
        failPolicy = EFAILURE_POLICY.FAIL_ON_ALL
        Logging.error("[_M:setPolicy()] failPolicy default is = FAIL_ON_ALL")
    end
    
    if not successPolicy then
        successPolicy = ESUCCESS_POLICY.SUCCEED_ON_ALL
        Logging.error("[_M:setPolicy()] successPolicy default is = SUCCEED_ON_ALL")
    end
    if not exitPolicty then
        exitPolicty = EEXIT_POLICY.EXIT_NONE
        Logging.error("[_M:setPolicy()] exitPolicty default is = EXIT_NONE")
    end
    self.m_failPolicy    = failPolicy
    self.m_succeedPolicy = successPolicy
    self.m_exitPolicy    = exitPolicty
end

function _M:isParallel()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:onEnter(agent, tick)
    local activeChildIndex = self:getActiveChildIndex(tick)
    _G.BEHAVIAC_ASSERT(activeChildIndex == constInvalidChildIndex)
    return true
end

function _M:onExit(agent, tick, status)

end

function _M:updateCurrent(agent, tick, childStatus)
    return self:update(agent, tick, childStatus)
end

function _M:update(agent, tick, childStatus)
    return self:parallelUpdate(agent, tick, self.m_children)
end

return _M