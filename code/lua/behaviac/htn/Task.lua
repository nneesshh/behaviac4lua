--- Behaviac lib Component: task htn node.
-- @module Task.lua
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
local Sequence = require(pdir .. "node.composites.Sequence")
local Task = class("Task", Sequence)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Task", Task)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Task", "Sequence")
local _M = Task

local NodeParser = require(pdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_bHTN     = false
    self.m_task     = false
    self.m_planner  = false
end

function _M:release()
    _M.super.release(self)

    self.m_task     = false
    self.m_planner  = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    for _, p in ipairs(properties) do
        local prototypeStr = p["Prototype"]
        local isHTNStr = p["IsHTN"]

        if nil ~= prototypeStr then
            self.m_task = NodeParser.parseMethod(prototypeStr)
        elseif nil ~= isHTNStr then
            self.m_bHTN = (isHTNStr == "true")
        else
            -- _G.BEHAVIAC_ASSERT(0, "unrecognized property")
        end
    end
end

function _M:FindMethodIndex(method)
    if self.m_children then
        for i, oneChild in ipairs(self.m_children) do
            if oneChild == method then
                return i
            end
        end
    end

    return constInvalidChildIndex
end

function _M:isHTN()
    return self.m_bHTN
end

function _M:isTask()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _G.BEHAVIAC_ASSERT(self:isTask(), "[_M:init()] node is not a task")

    if self:isHTN() then
        Branch.init(self, tick)
    else
        _M.super.init(self, tick)
    end
end

function _M:onEnter(agent, tick)
    self:setActiveChildIndex(tick, constInvalidChildIndex)

--[[#if BEHAVIAC_USE_HTN
        self.m_planner->Init(agent, pTaskNode)
#endif //BEHAVIAC_USE_HTN]]
        --_G.BEHAVIAC_UNUSED_VAR(pTaskNode)

    return _M.super.onEnter(self, agent, tick)
end

function _M:onExit(agent, tick, status)
    _M.super.onExit(self, agent, tick, status)
end

function _M:update(agent, tick, childStatus)
    local status = childStatus

    if childStatus == EBTStatus.BT_RUNNING then
        _G.BEHAVIAC_ASSERT(self:isTask(), "[_M:update()] node is not a task")

        if self:isHTN() then
--[[#if BEHAVIAC_USE_HTN
            status = self.m_planner->Update()
#endif //BEHAVIAC_USE_HTN]]
        else
            _G.BEHAVIAC_ASSERT(#self.m_children == 1)
            local pChild = self.m_children[1]
            status = tick:exec(pChild, agent)
        end
    end

    return status
end

return _M