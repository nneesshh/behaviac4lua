--- Behaviac lib Component: or condition node.
-- @module Or.lua
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
-- Boolean arithmetical operation ||
local Condition = require(ppdir .. "core.Condition")
local Cls_Or = class("Or", Condition)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Or", Cls_Or)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("Or", "Condition")
local _M = Cls_Or

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

function _M:evaluate(agent, tick)
    local ret = true
    for _, child in ipairs(self.m_children) do
        ret = child:evaluate(agent, tick)
        if ret then
            break
        end
    end

    return ret
end

function _M:isOr()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:update(agent, tick, childStatus)
    for _, pChild in ipairs(self.m_children) do
        local status = tick:exec(pChild, agent)
        -- If the child succeeds, succeeds
        if status == EBTStatus.BT_SUCCESS then
            return status
        end

        _G.BEHAVIAC_ASSERT(status == EBTStatus.BT_FAILURE, "[_M:update()] status == EBTStatus.BT_FAILURE")
    end

    return EBTStatus.BT_FAILURE
end

return _M