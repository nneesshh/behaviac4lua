--- Behaviac lib Component: assignment action node.
-- @module Assignment.lua
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
-- Assign a right value to left par or agent property. a right value can be a par or agent property.
local Leaf = require(ppdir .. "core.Leaf")
local Assignment = class("Assignment", Leaf)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Assignment", Assignment)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Assignment", "Leaf")
local _M = Assignment

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_opl      = false
    self.m_opr      = false
    self.m_bCast    = false
end

function _M:release()
    _M.super.release(self)

    self.m_opl      = false
    self.m_opr      = false
end

-- handle the Assignment property
function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    for _, p in ipairs(properties) do
        local castRightStr = p["CastRight"]
        local opLeftStr = p["Opl"]
        local opRightStr = p["Opr"]

        if nil ~= castRightStr then
            self.m_bCast = (castRightStr == "true")
        elseif nil ~= opLeftStr then
            self.m_opl = NodeParser.parseProperty(opLeftStr)
        elseif nil ~= opRightStr then
            local pParenthesis = string.find(opRightStr, '%(')
            if not pParenthesis then
                self.m_opr = NodeParser.parseProperty(opRightStr)
            else
                self.m_opr = NodeParser.parseMethod(opRightStr)
            end
        else
            -- _G.BEHAVIAC_ASSERT(0 == "unrecognized property")
        end
    end
end

function _M:isAssignment()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:onEnter(agent, tick)
    return true
end

function _M:onExit(agent, tick, status)
end

function _M:update(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(childStatus == EBTStatus.BT_RUNNING, "[_M:update()] childStatus == EBTStatus.BT_RUNNING")
    _G.BEHAVIAC_ASSERT(self:isAssignment(), "[_M:update()] self:isAssignment()")

    local status = EBTStatus.BT_SUCCESS

    if self.m_opl then
        self.m_opl:setValueCast(agent, self.m_opr, self.m_bCast)
    else
        status = self:evaluateImpl(agent, tick, childStatus)
    end

    return status
end

return _M