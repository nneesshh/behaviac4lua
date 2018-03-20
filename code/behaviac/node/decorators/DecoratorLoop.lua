--- Behaviac lib Component: failure until decorator node.
-- @module DecoratorLoop.lua
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
local EPreDecoratorPhase        = enums.EPreDecoratorPhase
local TriggerMode               = enums.TriggerMode
local EOperatorType             = enums.EOperatorType

local constSupportedVersion     = enums.constSupportedVersion
local constInvalidChildIndex    = enums.constInvalidChildIndex
local constBaseKeyStrDef        = enums.constBaseKeyStrDef
local constPropertyValueType    = enums.constPropertyValueType

local Logging                   = common.d_log
local StringUtils               = common.StringUtils

-- Class
-- DecoratorLoop can be set a integer Count value. It increases inner count value when it updates.
-- It always return Running until inner count less equal than integer Count value. Or returns the child
-- value. It always return Running when the count limit equal to -1.
local DecoratorCount = require(cwd .. "DecoratorCount")
local DecoratorLoop = class("DecoratorLoop", DecoratorCount)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorLoop", DecoratorLoop)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorLoop", "DecoratorCount")
local _M = DecoratorLoop

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_bDoneWithinFrame = false
end

function _M:release()
    _M.super.release(self)
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    for _, p in ipairs(properties) do
        local doneWithinFrameStr = p["DoneWithinFrame"]

        if nil ~= doneWithinFrameStr then
            self.m_bDoneWithinFrame = (doneWithinFrameStr == "true")
        end
    end   
end

function _M:isDecoratorLoop()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:update(agent, tick, childStatus)    
    _G.BEHAVIAC_ASSERT(self:isDecoratorLoop(), "[_M:update()] self:isDecoratorLoop")
    if self.m_bDoneWithinFrame then
        _G.BEHAVIAC_ASSERT(self.m_root, "[_M:update()] self.m_root")

        local num = self:getNum(tick)
        _G.BEHAVIAC_ASSERT(num >= 0, "[_M:update()] num >= 0")

        local status = EBTStatus.BT_INVALID
        for i = 1, num do
            status = tick:execWithChildStatus(self.m_root, agent, childStatus)
            if self.m_bDecorateWhenChildEnds then
                while status == EBTStatus.BT_RUNNING do
                    status = _M.super.update(self, agent, tick, childStatus)
                end
            end

            if status == EBTStatus.BT_FAILURE then
                return EBTStatus.BT_FAILURE
            end
        end

        return EBTStatus.BT_SUCCESS
    end
    
    return _M.super.update(self, agent, tick, childStatus)
end

--
function _M:decorate(status, tick)
    local num = self:getNum(tick)
    if num > 0 then
        num = num - 1
        self:setNum(tick, num)
        if num == 0 then
            return EBTStatus.BT_SUCCESS
        end
        return EBTStatus.BT_RUNNING
    end

    if num == -1 then
        return EBTStatus.BT_RUNNING
    end

    _G.BEHAVIAC_ASSERT(num == 0, "[_M:decorate()] num == 0")
    return EBTStatus.BT_SUCCESS
end

return _M