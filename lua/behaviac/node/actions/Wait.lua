--- Behaviac lib Component: wait action node.
-- @module Wait.lua
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
-- Wait for the specified milliseconds, and always return Running until time over.
local Leaf = require(ppdir .. "core.Leaf")
local Wait = class("Wait", Leaf)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Wait", Wait)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Wait", "Leaf")
local _M = Wait

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

    for _, p in ipairs(properties) do
        local waitTimeStr = p["Time"]

        if nil ~= waitTimeStr then
            if stringUtils.isValidString(waitTimeStr) then
                local pParenthesis = string.find(waitTimeStr, "%(")
                if not pParenthesis then
                    self.m_time_p = NodeParser.parseProperty(waitTimeStr)
                else
                    self.m_time_p = NodeParser.parseMethod(waitTimeStr)
                end
            end
        end
    end
end

function _M:getTimeP(agent)
    if self.m_time_p then
        return self.m_time_p:getValue(agent)
    end
    return agent:getTime()
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    self:setStart(tick, 0)
    self:setTime(tick, 0)
end

function _M:onEnter(agent, tick)
    self:setStart(tick, common.getClock())
    self:setTime(tick, self:getTimeP(agent) or 0)
    return self:getTime(tick) > 0 
end

function _M:onExit(agent, tick, status)
end

function _M:update(agent, tick, childStatus)
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