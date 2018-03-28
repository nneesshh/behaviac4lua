--- Behaviac lib Component: time decorator node.
-- @module DecoratorTime.lua
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
-- It returns Running result until it reaches the time limit specified, no matter which
-- value its child return. Or return the child's value.
local Decorator = require(ppdir .. "core.Decorator")
local DecoratorTime = class("DecoratorTime", Decorator)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorTime", DecoratorTime)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorTime", "Decorator")
local _M = DecoratorTime

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_time_p = false
end

function _M:release()
    _M.super.release(self)
    
    self.m_time_p = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "Time" then
            local pParenthesis = string.find(valueStr, "%(")
            if not pParenthesis then
                self.m_time_p = BehaviorParseFactory.parseProperty(valueStr)
            else
                self.m_time_p = BehaviorParseFactory.parseMethod(valueStr)
            end
        end
    end
end

function _M:getTimeP(agent)
    if self.m_time_p then
        return self.m_time_p
    end
    return agent:getTime()
end

function _M:isDecoratorTime()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)

    self:setStart(tick, 0)
    self:setTime(tick, 0)
end

function _M:onEnter(agent, tick)
    self:setStart(tick, common.getClock())
    self:setTime(tick, self:getTimeP(agent) or 0)

    return self:getTime(tick) > 0 
end

function _M:decorate(status, tick)
    local time = common.getColock()
    if time - self:getStart(tick) >= self:getTime(tick) then
        return EBTStatus.BT_SUCCESS
    end

    return EBTStatus.BT_RUNNING
end

function _M:setStart(tick, n)
    tick:setNodeMem("start", n, self)
end

function _M:getStart(tick)
    return tick:getNodeMem("start", self)
end

function _M:setTime(tick, tm)
    tick:setNodeMem("time", tm, self)
end

function _M:getTime(tick)
    return tick:getNodeMem("time", self)
end

return _M