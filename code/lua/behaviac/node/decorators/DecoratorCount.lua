--- Behaviac lib Component: count decorator node.
-- @module DecoratorCount.lua
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
local Decorator = require(ppdir .. "core.Decorator")
local DecoratorCount = class("DecoratorCount", Decorator)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorCount", DecoratorCount)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorCount", "Decorator")
local _M = DecoratorCount

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_count_p = false
end

function _M:release()
    _M.super.release(self)

    self.m_count_p = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    for _, p in ipairs(properties) do
        local countStr = p["Count"]

        if nil ~= countStr then
            self.m_count_p = NodeParser.parseProperty(countStr)
        end
    end
end

function _M:getCountP(agent)
    return self.m_count_p and self.m_count_p:getValue(agent) or 0
end

function _M:isDecoratorCount()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)

    self:setNum(tick, 0)
end

function _M:onReset(agent, tick)
    self:setNum(tick, 0)
end

function _M:onEnter(agent, tick)
    _M.super.onEnter(self, tick)

    local countP = self:getCountP(agent)
    if countP == 0 then
        return false
    end

    self:setNum(tick, countP)
    return true
end

function _M:setNum(tick, n)
    tick:setNodeMem("num", n, self)
end

function _M:getNum(tick)
    return tick:getNodeMem("num", self)
end

return _M