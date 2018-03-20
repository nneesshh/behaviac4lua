--- Behaviac lib Component: base agent.
-- @module BaseAgent.lua
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
local BaseAgent = class("BaseAgent")
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("BaseAgent", BaseAgent)
local _M = BaseAgent

local AgentMeta = require(cwd .. "AgentMeta")
local Blackboard = require(cwd .. "Blackboard")
local Tick = require(cwd .. "Tick")

local BehaviorTreeFactory = require(pdir .. "parser.BehaviorTreeFactory")

local BEHAVIAC_LOCAL_TASK_PARAM_PRE = "_$local_task_param_$_"

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    self.m_priority               = 0
    self.m_bActive                = true
    self.m_name                   = ""
    self.m_blackboard             = Blackboard.new(self)

    self.m_ttStack                = {}
    self.m_currentTreeTick        = false
    self.m_behaviorTreeTicks      = {}

    self.m_referencetree          = false

    self.m_lastExecutingTreeTick  = false
    self.m_executingTreeTick      = false

end

function _M:release()
    self.m_blackboard             = false
end

-- 
function _M:btExec()
    if self.m_bActive then
        local s = self:btExec_()
        while self.m_referencetree and s == EBTStatus.BT_RUNNING do
            self.m_referencetree = false
            s = self:btExec_()
        end
        return s
    end
    return EBTStatus.BT_INVALID
end

--
function _M:btExec_()
    if self.m_currentTreeTick ~= nil then
        local pLast = self.m_currentTreeTick
        local pBt = self.m_currentTreeTick:getBt()
        local s = self.m_currentTreeTick:exec(pBt, self)
        while s ~= EBTStatus.BT_RUNNING do
            -- self.m_currentTreeTick:reset(pBt, self)
            local len = #self.m_ttStack
            if len > 0 then
                -- get the last one
                local lastOne = self.m_ttStack[len]
                table.remove(self.m_ttStack, len)
                
                --
                self.m_currentTreeTick = lastOne.tt

                local bExecCurrent = false
                if lastOne.triggerMode == TriggerMode.TM_Return then
                    if not lastOne.triggerByEvent then
                        if self.m_currentTreeTick ~= pLast then
                            s = self.m_currentTreeTick:resume(self, s)
                        else
                            _G.BEHAVIAC_ASSERT(true)
                        end
                    else
                        bExecCurrent = true
                    end
                else
                    bExecCurrent = true
                end

                if bExecCurrent then
                    pLast = self.m_currentTreeTick
                    pBt = self.m_currentTreeTick:getBt()
                    s = self.m_currentTreeTick:exec(pBt, self)
                    break
                end
            else
                -- don't clear it
                -- self.m_currentTreeTick = 0
                break
            end
        end

        if s ~= EBTStatus.BT_RUNNING then
            self.m_currentBlackboard = 0
        end

        return s
    else
        -- _G.BEHAVIAC_LOGWARNING("NO ACTIVE BT!\n")
    end

    return EBTStatus.BT_INVALID
end

-- 
function _M:_btSetCurrent(relativePath, triggerMode, byEvent)
    if self.m_currentTreeTick then
        if triggerMode == TriggerMode.TM_Return then
            -- if trigger mode is 'return', just push the current bt 'oldBt' on the stack and do nothing more
            -- 'oldBt' will be restored when the new triggered one ends
            local item = {
                tt              = self.m_currentTreeTick,  -- tick
                triggerMode     = triggerMode, -- TriggerMode
                triggerByEvent  = byEvent,
            }
            _G.BEHAVIAC_ASSERT(#self.m_ttStack < 200, "recursive?")
            table.insert(self.m_ttStack, item)
        elseif triggerMode == TriggerMode.TM_Transfer then
            -- don't use the bt stack to restore, we just abort the current one.
            -- as the bt node has onEnter/onExit, the abort can make them paired
            --  //_G.BEHAVIAC_ASSERT(this->m_currentTreeTick->GetName() != relativePath);
            local pBt = self.m_currentTreeTick:getBt()
            self.m_currentTreeTick:abort(pBt, self)
            self.m_currentTreeTick:reset(pBt, self)
        end
    end

    -- 
    local pTick = false
    for _, tick in ipairs(self.m_behaviorTreeTicks) do
        _G.BEHAVIAC_ASSERT(tick)
        if tick:getBt():getRelativePath(self) == relativePath then
            pTick = tick
            break
        end
    end

    local bRecursive = false
    if pTick then
        for _, item in ipairas(self.m_ttStack) do
            if item.tt:getBt():getRelativePath() == relativePath then
                bRecursive = true
                break
            end
        end

        local pBt = pTick:getBt()
        if pBt:getStatus(pTick) ~= EBTStatus.BT_INVALID then
            pTick:reset(pBt, self)
        end
    end

    if pTick == false or bRecursive then
        pTick = self:btCreateTreeTick(relativePath)
    end

    -- set current
    self.m_currentTreeTick = pTick
    return pTick
end

function _M:btSetCurrent(relativePath)
    return self:_btSetCurrent(relativePath, TriggerMode.TM_Transfer, false)
end

function _M:btReferenceTree(relativePath)
    self.m_referencetree = true
    return self:_btSetCurrent(relativePath, TriggerMode.TM_Return, false)
end

function _M:btEventTree(relativePath, triggerMode)
    return self:_btSetCurrent(relativePath, triggerMode, true)
end

function _M:btOnEvent(eventName, eventParams)
    if self.m_currentTreeTick then
        local pBt = self.m_currentTreeTick:getBt()
        pBt:onEvent(self, self.m_currentTreeTick, eventName, eventParams)
    end
end

function _M:btCreateTreeTick(relativePath)
    local bt = BehaviorTreeFactory.preloadBehaviorTree(relativePath)
    local tick = Tick.new(bt, self.m_blackboard)
    tick:init()
    table.insert(self.m_behaviorTreeTicks, tick)
    return tick
end

function _M:fireEvent(eventName, ...)
    local args = {...}
    local eventParams = {}
    
    for i, param in ipairs(args) do
        local paramName = BEHAVIAC_LOCAL_TASK_PARAM_PRE .. tostring(i - 1)
        eventParams[paramName] = param
    end

    self:btOnEvent(eventName, eventParams);
end

function _M:getObjectTypeName()
    return self[constBaseKeyStrDef.kStrClass].__cname
end

function _M:isActive()
    return self.m_bActive
end

function _M:resetCurrentTreeTick()
    if self.m_currentTreeTick then
        local pBt = self.m_currentTreeTick:getBt()
        self.m_currentTreeTick:reset(pBt, self)
    end
end

function _M:getCurrentTreeTick()
    return self.m_currentTreeTick
end

function _M:pushExecutingTreeTick(tick)
    self.m_lastExecutingTreeTick = self.m_executingTreeTick
    self.m_executingTreeTick = tick
end

function _M:popExecutingTreeTick()
    self.m_executingTreeTick = self.m_lastExecutingTreeTick
    return self.m_executingTreeTick
end

function _M:setLocalVariable(varName, value)
    self.m_blackboard:setLocalVariable(varName, value)
end

function _M:addLocalVariables(vars)
    self.m_blackboard:addLocalVariables(vars)
end

function _M:getLocalVariable(varName)
    return self.m_blackboard:getLocalVariable(varName)
end

return _M