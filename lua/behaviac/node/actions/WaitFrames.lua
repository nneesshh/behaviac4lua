--- Behaviac lib Component: wait frames action node.
-- @module WaitFrames.lua
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
-- Wait for the specified frames, and always return Running until exceeds count.
local Leaf = require(ppdir .. "core.Leaf")
local WaitFrames = class("WaitFrames", Leaf)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("WaitFrames", WaitFrames)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("WaitFrames", "Leaf")
local _M = WaitFrames

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_frames_p = false
end

function _M:release()
    _M.super.release(self)

    self.m_frames_p = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "Frames" then
            local pParenthesis = string.find(valueStr, "%(")
            if not pParenthesis then
                self.m_frames_p = NodeParser.parseProperty(valueStr)
            else
                self.m_frames_p = NodeParser.parseMethod(valueStr)
            end
        end
    end
end

function _M:getFramesP()
    if self.m_frames_p then
        local frames = self.m_frames_p:getValue()
        if frames == 0xFFFFFFFF then
            return -1
        end
        return frames
    end
    
    return 0
end

function _M:isWaitFrames()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    self:setStart(tick, 0)
    self:setFrames(tick, 0)
end

function _M:onEnter(agent, tick)
    self:setStart(tick, common.getFrames())
    self:setFrames(tick, self:getFramesP() or 0)

    return self:getFrames() > 0
end

function _M:onExit(agent, tick)
end

function _M:update(agent, tick, childStatus)
    local frames = common.getFrames()
    if frames - self:getStart(tick) + 1 >= self:getFrames(tick) then
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

function _M:setFrames(tick, n)
    tick:setNodeMem("frames", n, self)
end

function _M:getFrames(tick)
    return tick:getNodeMem("frames", self)
end

return _M