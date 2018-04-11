--- Behaviac lib Component: with precondition composite node.
-- @module WithPrecondition.lua
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
local Sequence = require(cwd .. "Sequence")
local WithPrecondition = class("WithPrecondition", Sequence)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("WithPrecondition", WithPrecondition)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("WithPrecondition", "Sequence")
local _M = WithPrecondition

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)
end

function _M:release()
    _M.super.release(self)
end

function _M:preconditionNode()
    _G.BEHAVIAC_ASSERT(#self.m_children == 2, "[_M:preconditionNode()] #self.m_children == 2")
    return self.m_children[1]
end

function _M:actionNode()
    _G.BEHAVIAC_ASSERT(#self.m_children == 2, "[_M:actionNode()] #self.m_children == 2")
    return self.m_children[2]
end

function _M:isWithPrecondition()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:onEnter(agent, tick)
    local pParent = self:getParent()
    -- when not as child of SelctorLoop, it is not ticked normally
    _G.BEHAVIAC_ASSERT(pParent and pParent:isSelectorLoop(), "[_M:onEnter()] pParent:isSelectorLoop")
    return true
end

function _M:onExit(agent, tick, status)
    local pParent = self:getParent()
    -- when not as child of SelctorLoop, it is not ticked normally
    _G.BEHAVIAC_ASSERT(pParent and pParent:isSelectorLoop(), "[_M:onExit()] pParent:isSelectorLoop")
end

function _M:updateCurrent(agent, tick, childStatus)
    return self:update(agent, tick, childStatus)
end

function _M:update(agent, tick, childStatus)
    -- REDO: 因为_G.BEHAVIAC_ASSERT(false) 这个不应该被调用
    local pParent = self.getParent()
    _G.BEHAVIAC_ASSERT(pParent and pParent:isSelectorLoop(), "[_M:update()] pParent:isSelectorLoop")
    _G.BEHAVIAC_ASSERT(#self.m_children == 2, "[_M:update()] #self.m_children == 2")
    _G.BEHAVIAC_ASSERT(false)
    return EBTStatus.BT_RUNNING
end

return _M