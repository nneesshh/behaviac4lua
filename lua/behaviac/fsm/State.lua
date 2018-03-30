--- Behaviac lib Component: state fms node.
-- @module State.lua
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
local BaseNode = require(pdir .. "core.BaseNode")
local State = class("State", BaseNode)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("State", State)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("State", "BaseNode")
local _M = State

local NodeParser = require(pdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_bIsEndState = false
    self.m_method = false
    self.m_transitions = {}
end

function _M:release()
    _M.super.release(self)

    self.m_method = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "Method" then
            self.m_method = NodeParser.parseMethod(valueStr)
        elseif nameStr == "IsEndState" then
            self.m_bIsEndState = (valueStr == "true")
        else
            -- _G.BEHAVIAC_ASSERT(0, "unrecognized property")
        end
    end
end

function _M:attach(pAttachment, bIsPrecondition, bIsEffector, bIsTransition)
    if bIsTransition then
        _G.BEHAVIAC_ASSERT(not bIsEffector and not bIsPrecondition, "Transition flag conficts with effector and precondition flag")

        local pTransition = pAttachment
        _G.BEHAVIAC_ASSERT(pTransition, "Transition node cann't be nil")
        return table.insert(self.m_transitions, pTransition)
    else
        return _M.super.attach(self, pAttachment, bIsPrecondition, bIsEffector, bIsTransition)
    end
end

-- nextStateId holds the next state id if it returns running when a certain transition is satisfied
-- otherwise, it returns success or failure if it ends
function _M:stateUpdate(agent, tick, nextStateId)
    nextStateId = -1

    -- when no method is specified(m_method == 0),
    -- 'evaluateImpl' is used to return the configured result status for both xml/bson and c#
    local status = self.execute(agent, tick)

    if self.m_bIsEndState then
        status = EBTStatus.BT_SUCCESS
    else
        local bTransitioned, nextStateId = _M.s_updateTransitions(self, agent, tick, self.m_transitions, nextStateId, status)

        if bTransitioned then
            -- it will transition to another state, set result as success so as it exits
            status = EBTStatus.BT_SUCCESS
        end
    end

    return status
end

function _M.s_updateTransitions(targetNode, agent, tick, transitions, nextStateId, status)
    --_G.BEHAVIAC_UNUSED_VAR(targetNode)
    local bTransitioned = false

    if transitions and #transitions > 0 then
        for _, transition in ipairs(transitions) do
            if transition:evaluate(agent, tick, status) then
                nextStateId = transition.getTargetStateId()
                _G.BEHAVIAC_ASSERT(nextStateId ~= -1, "Invalid nextStateId")

                -- transition actions
                transition:applyEffects(agent, tick, ENodePhase.E_BOTH)

--[[
#if !BEHAVIAC_RELEASE

                if (Config::IsLoggingOrSocketing()) {
                    CHECK_BREAKPOINT(agent, targetNode, "transition", EAR_none)
                }

#endif
]]
                bTransitioned = true
                break
            end
        end
    end

    return bTransitioned, nextStateId
end

function _M:isEndState()
    return self.m_bIsEndState
end

function _M:isState()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)

    setNextStateId(tick, -1)
end

function _M:onEnter(agent, tick)
    --_G.BEHAVIAC_UNUSED_VAR(agent)
    self:setNextStateId(tick, -1)
    return true
end

function _M:onExit(agent, tick, status)
    --_G.BEHAVIAC_UNUSED_VAR(agent)
    --_G.BEHAVIAC_UNUSED_VAR(status)
end

function _M:update(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(childStatus == BT_RUNNING)
    --_G.BEHAVIAC_UNUSED_VAR(childStatus)
    _G.BEHAVIAC_ASSERT(self:isState(), "[_M:update()] node is not a state")

    local nextStateId = self:getNextStateId(tick)
    return self:stateUpdate(agent, tick, nextStateId)
end

function _M:evaluateImpl(agent, tick, childStatus)
    return EBTStatus.BT_RUNNING
end

function _M:execute(agent, tick)
    local status = EBTStatus.BT_RUNNING

    if self.m_method then
        self.m_method:run(agent, tick)
    else
        status = self:evaluateImpl(agent, tick, EBTStatus.BT_RUNNING)
    end

    return status
end

function _M:setNextStateId(tick, id)
    tick:setNodeMem("nextStateId", id, self)
end

function _M:getNextStateId(tick)
    return tick:getNodeMem("nextStateId", self)
end

return _M