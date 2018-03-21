--- Behaviac lib Component: composite node.
-- @module Composite.lua
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
local Branch = require(cwd .. "Branch")
local Composite = class("Composite", Branch)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Composite", Composite)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Composite", "Branch")
local _M = Composite

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_children         = {}
end

function _M:release()
    _M.super.release(self)

    for _, child in ipairs(self.m_children) do
        child:release()
    end
    self.m_children = {}
end

function _M:isComposite()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)
    _G.BEHAVIAC_ASSERT(self:getChildrenCount() > 0, "self:getChildrenCount() > 0")

    local childrenCount = self:getChildrenCount()
    for index = 1, childrenCount do
        local childNode = self:getChild(index)
        childNode:init(tick)
    end
end

function _M:traverse(childFirst, handler, agent, userData)
    if childFirst then
        for _, child in ipairs(self.m_children) do
            child:traverse(childFirst, handler, agent, userData)
        end
        handler(self, agent, userData)
    else
        if handler(self, agent, userData) then
            for _, child in ipairs(self.m_children) do
                child:traverse(childFirst, handler, agent, userData)
            end
        end
    end
end

function _M:setActiveChildIndex(tick, index)
    tick:setNodeMem("activeChildIndex", index, self)
end

function _M:getActiveChildIndex(tick)
    return tick:getNodeMem("activeChildIndex", self)
end

return _M