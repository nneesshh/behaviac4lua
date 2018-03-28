--- Behaviac lib Component: selector loop composite node.
-- @module SelectorLoop.lua
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
-- Behavives similarly to Selector, i.e. executing chidren until the first successful one.
-- however, in the following ticks, it constantly monitors the higher priority nodes.if any
-- one's precondtion node returns success, it picks it and execute it, and before executing,
-- it first cleans up the original executing one. all its children are WithPrecondition
local Composite = require(ppdir .. "core.Composite")
local SelectorLoop = class("SelectorLoop", Composite)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("SelectorLoop", SelectorLoop)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("SelectorLoop", "Composite")
local _M = SelectorLoop

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_bResetChildren = false
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

        if nameStr == "ResetChildren" then
            self.m_bResetChildren = (valueStr == "true")
            break
        end
    end
end

function _M:isManagingChildrenAsSubTrees()
    return true
end

function _M:isSelectorLoop()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:onEnter(agent, tick)
    self:setActiveChildIndex(tick, constInvalidChildIndex)
    return _M.super.onEnter(self, agent, tick) 
end

function _M:updateCurrent(agent, tick, childStatus)
    return self:update(agent, tick, childStatus)
end

function _M:update(agent, tick, childStatus)
    local idx = 0
    local activeChildIndex = self:getActiveChildIndex(tick)

    if childStatus ~= EBTStatus.BT_RUNNING then
        _G.BEHAVIAC_ASSERT(activeChildIndex ~= constInvalidChildIndex, "[_M:update()] activeChildIndex ~= constInvalidChildIndex")
        if childStatus == EBTStatus.BT_SUCCESS then
            return EBTStatus.BT_SUCCESS
        elseif childStatus == EBTStatus.BT_FAILURE then
            -- the next for starts from (idx + 1), so that it starts from next one after this failed one
            idx = activeChildIndex
        else
            _G.BEHAVIAC_ASSERT(false)
        end
    end

    -- checking the preconditions and take the first action tree
    local index = -1
    for i = idx + 1, #self.m_children do
        local pChild = self.m_children[i]
        _G.BEHAVIAC_ASSERT(pChild:isWithPrecondition(), "[_M:update()] pChild:isWithPrecondition()")

        local pPrecondition = pChild.preconditionNode()
        local status = tick:exec(pPrecondition, agent)
        if status == EBTStatus.BT_SUCCESS then
            index = i
            break
        end
    end

    -- clean up the current ticking action tree
    if index ~= -1 then
        if activeChildIndex ~= constInvalidChildIndex then
            local abortChild = (activeChildIndex ~= index)
            if not abortChild then
                abortChild = self.m_bResetChildren
            end

            if abortChild then
                local pChild = self.m_children[activeChildIndex]
                _G.BEHAVIAC_ASSERT(pChild:isWithPrecondition(), "[_M:update()] pChild:isWithPrecondition()")
                pCurrentSubTree:abort(agent)
            end
        end

        for i = index, #self.m_children do
            local pChild = self.m_children[i]
            _G.BEHAVIAC_ASSERT(pChild:isWithPrecondition(), "[_M:update()] pChild:isWithPrecondition()")

            if i >= index then
                local pPrecondition = pChild:preconditionNode()
                local status = tick:exec(pPrecondition, agent)

                -- to search for the first one whose precondition is success
                if status == EBTStatus.BT_SUCCESS then
                    local pAction = pChild:actionNode()
                    local s = tick:exec(pAction, agent)
        
                    if s == EBTStatus.BT_RUNNING then
                        activeChildIndex = i
                        self:setActiveChildIndex(tick, activeChildIndex)
                        pChild.setStatus(tick, EBTStatus.BT_RUNNING)
                        return s
                    else
                        pChild.setStatus(tick, s)
                        if s ~= EBTStatus.BT_FAILURE then
                            -- THE ACTION failed, to try the next one
                            _G.BEHAVIAC_ASSERT(s == EBTStatus.BT_RUNNING or s == EBTStatus.BT_SUCCESS, "[_M:update()] s == EBTStatus.BT_RUNNING or s == EBTStatus.BT_SUCCESS")
                            return s
                        end
                    end
                end
            end
        end
    end
    
    return EBTStatus.BT_FAILURE
end

return _M