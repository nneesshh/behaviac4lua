--- Behaviac lib Component: iterator decorator node.
-- @module DecoratorIterator.lua
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
local DecoratorIterator = class("DecoratorIterator", Decorator)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("DecoratorIterator", DecoratorIterator)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("DecoratorIterator", "Decorator")
local _M = DecoratorIterator

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_opl = false
    self.m_opr = false
end

function _M:release()
    _M.super.release(self)

    self.m_opl = false
    self.m_opr = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    for _, p in ipairs(properties) do
        local opLeftStr = p["Opl"]
        local opRightStr = p["Opr"]

        if nil ~= opLeftStr then
            local pParenthesis = string.find(opLeftStr, '%(')
            if not pParenthesis then
                self.m_Iterator = NodeParser.parseProperty(opLeftStr)
            else
                _G.BEHAVIAC_ASSERT(false, "[_M:onLoading()] Opl if function")
            end
        elseif nil ~= opRightStr then
            local pParenthesis = string.find(opRightStr, '%(')
            if not pParenthesis then
                self.m_Iterator = NodeParser.parseProperty(opRightStr)
            else
                self.m_Iterator = NodeParser.parseMethod(opRightStr)
            end
        else
            -- do nothing
        end
    end
end

function _M:iterateIt(agent, index, outCount)
    if self.m_opl and self.m_opr then
        outCount = self.m_opr:getValue(agent)
        if index >= 0 and index < outCount then
            self.m_opl:setValueElement(agent, self.m_opr, index)
            return true, outCount
        end
    else
        _G.BEHAVIAC_ASSERT(false, "[_M:iterateIt()] ")
    end

    return false, outCount
end

function _M:isDecoratorIterator()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

return _M