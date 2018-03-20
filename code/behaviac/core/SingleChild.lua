--- Behaviac lib Component: single child node.
-- @module SingleChild.lua
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
local SingleChild = class("SingleChild", Branch)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("SingleChild", SingleChild)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("SingleChild", "Branch")
local _M = SingleChild

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_root = false
end

function _M:release()
    _M.super.release(self)

    if self.m_root then
        self.m_root:release()
    end
    self.m_root = false
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)
    _G.BEHAVIAC_ASSERT(self:getChildrenCount() <= 1, "[_M:init()] node:getChildrenCount() <= 1")
    
    if self:getChildrenCount() == 1 then
        local childNode = self:getChild(1)
        childNode:init(tick)
    else
        Logging.error("[_M:init()] do nothing")
    end
end

function _M:traverse(childFirst, handler, agent, userData)
    if childFirst then
        if self.m_root then
            self.m_root:traverse(childFirst, handler, agent, userData)
        end
        handler(self, agent, userData)
    else
        if handler(self, agent, userData) then
            if self.m_root then
                self.m_root:traverse(childFirst, handler, agent, userData)
            end
        end
    end
end

function _M:update(agent, tick, childStatus)
    if self.m_root then
        return tick:execWithChildStatus(self.m_root, agent, childStatus)
    end

    return EBTStatus.BT_FAILURE
end

function _M:addChild(child)
    _M.super.addChild(self, child)

    self.m_root = child
end

return _M