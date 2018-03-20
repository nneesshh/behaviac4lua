--- Behaviac lib Component: repeat decorator node.
-- @module DecoratorRepeat.lua
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
local DecoratorCount = require(cwd .. "DecoratorCount")
local DecoratorRepeat = class("DecoratorRepeat", DecoratorCount)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorRepeat", DecoratorRepeat)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorRepeat", "DecoratorCount")
local _M = DecoratorRepeat

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

function _M:isDecoratorRepeat()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:update(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(self:isDecoratorRepeat(), "[_M:update()] self:isDecoratorRepeat")
    _G.BEHAVIAC_ASSERT(self.m_root,  "[_M:update()] self.m_root")

    local num = self:getNum(tick)
    _G.BEHAVIAC_ASSERT(num >= 0, "[_M:update()] num >= 0")

    local status = EBTStatus.BT_INVALID

    for i = 1, n do
        status = tick:exec(self.m_root, agent, childStatus)

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

function _M:decorate(status, tick)
    _G.BEHAVIAC_ASSERT(false, "[_M:decorate()]")
    return EBTStatus.BT_INVALID
end

return _M